//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Agata Menes on 11/07/2022.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
}

// MARK: - account management

extension DatabaseManager {
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        // completion handlers stand for: Do stuff when things have been done
        
        //Escaping Closure : An escaping closure is a closure that’s called after the function it was passed to returns. In other words, it outlives the function it was passed to.
        
        database.child(email).observeSingleEvent(of: .value,
                                                 with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
        
        
    }
    
    /// inserts new user to database
    public func insertUser(with user: ChatAppUser) {
        database.child(user.emailAdress).setValue([ // key of user is email
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
   // let profilePicutreUrl: String
}
