//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Agata Menes on 11/07/2022.
//

import Foundation
import FirebaseDatabase
import RealmSwift
import UIKit
import CoreMedia
import SwiftUI

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAdress: String) -> String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        return safeEmail
    }
}

// MARK: - account management

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        })
        
    }
}

extension DatabaseManager {
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        // completion handlers stand for: Do stuff when things have been done
        
        //Escaping Closure : An escaping closure is a closure that’s called after the function it was passed to returns. In other words, it outlives the function it was passed to.
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        
        database.child(safeEmail).observeSingleEvent(of: .value,
                                                 with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
        
    }
    
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([ // key of user is email
            "first_name": user.firstName,
            "last_name": user.lastName
            ], withCompletionBlock: { error, _ in
                guard error == nil else {
                    print("failed to write to database")
                    completion(false)
                    return
                }

                self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        
                        let newUser = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        usersCollection.append(newUser)
                        
                self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                        }
                            completion(true)
                        })
                        
                    } else {
                        let newCollection: [[String: String]] = [
                            [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                            ]
                        ]
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                })
            })
        }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseErrors: Error {
        case failedToFetch
    }
}

// MARK: - sending messages / conversations

extension DatabaseManager {
    
    /*
     "coverID" {
        "messages": [
            {
                "id": String,
                "type": text, photo, video,
                "content": String, photoURL, viedo,
                "date": Date(),
                "sender_email": String,
                "isRead": True/False,
            }
        ]
     }
     
        conversation => [
            [
                "conversation_id: "coverID"
                "other_user_email:
                    "latest_message": => {
                        "date": Date()
                        "lates_message": "message"
                        "is_read: true/false
            }
        ]
     ]
     */
    
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentUserName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        let referenceToCurrentUser = database.child("\(currentUserSafeEmail)")
        
        referenceToCurrentUser.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let messageDateAsString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            //FIXME:
            
            let conversationID = "conversation_\(firstMessage.messageId)".replacingOccurrences(of: "/", with: "_")
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "lastest_message": [
                    "date": messageDateAsString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipientNewConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": currentUserSafeEmail,
                "name": currentUserName,
                "lastest_message": [
                    "date": messageDateAsString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            self?.database.child("\(otherUserEmail)/conversation").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversation").setValue(conversations)
                } else {
                    self?.database.child("\(otherUserEmail)/conversation").setValue([recipientNewConversationData])
                }
            })
            
            if var conversation = userNode["conversation"] as? [[String: Any]] {
                //conversation array exists for current user
                //you should append
                
                conversation.append(newConversationData)
                userNode["conversation"] = conversation
                
                referenceToCurrentUser.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
            else {
                //create array
                userNode["conversation"] = [
                    newConversationData
                ]
                
                referenceToCurrentUser.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        let messageDate = firstMessage.sentDate
        let messageDateAsString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        let messageId = firstMessage.messageId
        let safeMessageId = messageId.replacingOccurrences(of: "/", with: "_")
        let collectionMessage: [String: Any] = [
            "id": safeMessageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": messageDateAsString,
            "sender_email": currentUserSafeEmail,
            "is_read": false,
            "name": name
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        print(value)
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversation").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            print(value)
            let conversation: [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["lastest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                let latestMessageObject = LatestMessage(message: message,
                                                        date: date,
                                                        isRead: isRead)

                return Conversation(id: conversationID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            
            completion(.success(conversation))
        })
    }
    
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let messageID = dictionary["id"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            })
            
            completion(.success(messages))
        })
    }
    
    public func sendMessage(to conversation: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void){
        //TODO: add new message to messages
        //TODO: update sender latest message
        //TODO: update recipient latest message
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let messageDateAsString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserSafeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
            let messageId = newMessage.messageId
            let safeMessageId = messageId.replacingOccurrences(of: "/", with: "_")
            
            let newMessageEntry: [String: Any] = [
                "id": safeMessageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": messageDateAsString,
                "sender_email": currentUserSafeEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            })
        })
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
    
    var safeEmail: String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        return safeEmail
    }
    
    var profilePicutreFileName: String {
        //agatamenes_gmail_com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
    
}
