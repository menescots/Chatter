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
    
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        let referenceToCurrentUser = database.child("\(currentUserSafeEmail)")
        referenceToCurrentUser.observeSingleEvent(of: .value, with: { snapshot in
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
            
            let newConversationData: [String: Any] = [
                "id": "conversation_\(firstMessage.messageId)",
                "other_user_email": otherUserEmail,
                "lastest_message": [
                    "date": messageDateAsString,
                    "message": message,
                    "is_read:": false
                ]
            ]
            
            if var conversation = userNode["conversation"] as? [[String: Any]] {
                //conversation array exists for current user
                //you should append
                
                conversation.append(newConversationData)
                userNode["conversation"] = conversation
                
                referenceToCurrentUser.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
            else {
                //create array
                userNode["conversation"] = [
                    newConversationData
                ]
                
                referenceToCurrentUser.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
        })
    }
    
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void){
        
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
