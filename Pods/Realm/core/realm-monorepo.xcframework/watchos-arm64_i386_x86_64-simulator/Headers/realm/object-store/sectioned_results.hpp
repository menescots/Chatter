////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#ifndef REALM_SECTIONED_RESULTS_HPP
#define REALM_SECTIONED_RESULTS_HPP

#include <realm/util/functional.hpp>

#include <list>

namespace realm {
class Mixed;
class Results;
class SectionedResults;
struct SectionedResultsChangeSet;

/// For internal use only. Used to track the indices for a given section.
struct Section {
    Section() = default;
    size_t index = 0;
    Mixed key;
    std::vector<size_t> indices;
};

using SectionedResultsNotificatonCallback = util::UniqueFunction<void(SectionedResultsChangeSet, std::exception_ptr)>;

/**
 * An instance of ResultsSection gives access to elements in the underlying collection that belong to a given section
 * key.
 *
 * A ResultsSection is only valid as long as it's `SectionedResults` parent stays alive.
 *
 * You can register a notification callback for changes which will only deliver if the change indices match the
 * section key bound in this `ResultsSection`.
 */
class ResultsSection {
public:
    ResultsSection();

    /// Retrieve an element from the section for a given index.
    Mixed operator[](size_t idx) const;

    /// The key identifying this section.
    Mixed key();

    /// The index of this section in the parent `SectionedResults`.
    size_t index();

    /// The total count of elements in this section.
    size_t size();

    /**
     * Create an async query from this ResultsSection
     * The query will be run on a background thread and delivered to the callback,
     * and then rerun after each commit (if needed) and redelivered if it changed.
     *
     * NOTE: Notifications will only be delivered if the change indices match the current or
     * previous location of the section key bound to this `ResultsSection`.
     *
     * @param callback The function to execute when a insertions, modification or deletion in this `ResultsSection`
     * was detected.
     * @param key_path_array A filter that can be applied to make sure the `SectionedResultsNotificatonCallback` is
     * only executed when the property in the filter is changed but not otherwise.
     *
     * @return A `NotificationToken` that is used to identify this callback. This token can be used to remove the
     * callback via `remove_callback`.
     */
    NotificationToken add_notification_callback(SectionedResultsNotificatonCallback callback,
                                                KeyPathArray key_path_array = {}) &;

    bool is_valid() const;

private:
    friend class SectionedResults;
    ResultsSection(SectionedResults* parent, Mixed key);

    SectionedResults* m_parent;
    Mixed m_key;
    std::unique_ptr<char[]> m_key_buffer;
    Section* get_if_valid() const;
};

/**
 * An instance of `SectionedResults` allows access to elements from underlying `Results` collection
 * where elements are arranged into sections defined by a key either from a user defined sectioning algorithm
 * or a predefined built-in sectioning algorithm. Elements are then accessed through a `ResultsSection` which can be
 * retreived through the subscript operator on `SectionedResults`.
 */
class SectionedResults {
public:
    SectionedResults() = default;
    using SectionKeyFunc = util::UniqueFunction<Mixed(Mixed value, SharedRealm realm)>;

    /**
     * Returns a `ResultsSection` which will be bound to a section key present at the given index in
     * `SectionedResults`.
     *
     * NOTE: A `ResultsSection` is lazily retreived, meaning that the index it was retreived from
     * is not guaranteed to be the index of this `ResultsSection` at the time of access.
     * For example if this `ResultsSection` is at index 1 and the  `ResultsSection`
     * below this one is deleted, this `ResultsSection` will now be at index 0
     * but will continue to be a container for elements only refering to the section key it was originally bound to.
     */
    ResultsSection operator[](size_t idx) REQUIRES(!m_mutex);
    /**
     * Returns a `ResultsSection` for a given key. This method will throw
     * if the key does not already exist.
     */
    ResultsSection operator[](Mixed key) REQUIRES(!m_mutex);
    /// The total amount of Sections.
    size_t size() REQUIRES(!m_mutex);

    /**
     * Create an async query from this SectionedResults
     * The query will be run on a background thread and delivered to the callback,
     * and then rerun after each commit (if needed) and redelivered if it changed
     *
     * @param callback The function to execute when a insertions, modification or deletion in this `SectionedResults`
     * was detected.
     * @param key_path_array A filter that can be applied to make sure the `SectionedResultsNotificatonCallback` is
     * only executed when the property in the filter is changed but not otherwise.
     *
     * @return A `NotificationToken` that is used to identify this callback. This token can be used to remove the
     * callback via `remove_callback`.
     */
    NotificationToken add_notification_callback(SectionedResultsNotificatonCallback callback,
                                                KeyPathArray key_path_array = {}) &;

    /// Return a new instance of SectionedResults that uses a snapshot of the underlying `Results`.
    /// The section key callback parameter will never be invoked.
    SectionedResults snapshot() REQUIRES(!m_mutex);

    /// Return a new instance of SectionedResults that uses a frozen version of the underlying `Results`.
    /// The section key callback parameter will never be invoked.
    /// This SectionedResults can be used across threads.
    SectionedResults freeze(std::shared_ptr<Realm> const& frozen_realm) REQUIRES(!m_mutex);

    bool is_valid() const;
    bool is_frozen() const REQUIRES(!m_mutex);
    /// Replaces the function which will perform the sectioning on the underlying results.
    void reset_section_callback(SectionKeyFunc section_callback) REQUIRES(!m_mutex);

    // The input index parameter was out of bounds
    struct OutOfBoundsIndexException : public std::out_of_range {
        OutOfBoundsIndexException(size_t r, size_t c);
        const size_t requested;
        const size_t valid_count;
    };

private:
    friend class Results;
    /// SectionedResults should not be created directly and should only be instantiated from `Results`.
    SectionedResults(Results results, SectionKeyFunc section_key_func);
    SectionedResults(Results results, Results::SectionedResultsOperator op, util::Optional<StringData> prop_name);

    /// Used for creating a frozen or snapshot of SectionedResults.
    SectionedResults(Results&& results, std::map<Mixed, Section>&& sections,
                     std::map<size_t, Mixed>&& current_section_index_to_key_lookup,
                     std::list<std::string>&& current_str_buffers)
        : has_performed_initial_evalutation(true)
        , m_results(std::move(results))
        , m_sections(std::move(sections))
        , m_current_section_index_to_key_lookup(std::move(current_section_index_to_key_lookup))
        , m_current_str_buffers(std::move(current_str_buffers))
    {
    }

    friend struct SectionedResultsNotificationHandler;
    util::CheckedOptionalMutex m_mutex;
    SectionedResults copy(Results&&) REQUIRES(!m_mutex);
    void calculate_sections_if_required() REQUIRES(m_mutex);
    void calculate_sections() REQUIRES(m_mutex);
    bool has_performed_initial_evalutation = false;
    NotificationToken add_notification_callback_for_section(Mixed section_key,
                                                            SectionedResultsNotificatonCallback callback,
                                                            KeyPathArray key_path_array = {});

    friend class realm::ResultsSection;
    Results m_results;
    SectionKeyFunc m_callback;
    std::map<Mixed, Section> m_sections GUARDED_BY(m_mutex);
    // Returns the key of the current section from its index.
    std::map<size_t, Mixed> m_current_section_index_to_key_lookup GUARDED_BY(m_mutex);
    // Stores the Key, Section Index of the previous section
    // so we can efficiently calculate the collection change set.
    std::map<Mixed, size_t> m_previous_key_to_index_lookup;
    // Returns the key of the previous section from its index.
    std::map<size_t, Mixed> m_prev_section_index_to_key;
    // By passing the index of the object from the underlying `Results`,
    // this will give a pair with the section index of the object, and the position of the object in that section.
    // This is used for parsing the indices in CollectionChangeSet to section indices.
    std::vector<std::pair<size_t, size_t>> m_row_to_index_path;
    // BinaryData & StringData types require a buffer to hold deep
    // copies of the key values for the lifetime of the sectioned results.
    // This is due to the fact that such values can reference the memory address of the value in the realm.
    // We can not rely on that because it would not produce stable keys.
    // So we perform a deep copy to produce stable key values that will not change if the realm is modified.
    // The buffer will purge keys that are no longer used in the case that the `calculate_sections` method runs.
    std::list<std::string> m_previous_str_buffers, m_current_str_buffers GUARDED_BY(m_mutex);
};

struct SectionedResultsChangeSet {
    /// Sections and indices in the _new_ collection which are new insertions
    std::map<size_t, IndexSet> insertions;
    /// Sections and indices of objects in the _old_ collection which were modified
    std::map<size_t, IndexSet> modifications;
    /// Sections and indices which were removed from the _old_ collection
    std::map<size_t, IndexSet> deletions;
    /// Indexes of sections which are newly inserted.
    IndexSet sections_to_insert;
    /// Indexes of sections which are deleted from the _old_ collection.
    IndexSet sections_to_delete;
};

} // namespace realm


#endif /* REALM_SECTIONED_RESULTS_HPP */
