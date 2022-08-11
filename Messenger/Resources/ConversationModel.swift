//
//  ConversationModel.swift
//  Messenger
//
//  Created by Agata Menes on 11/08/2022.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let message: String
    let date: String
    let isRead: Bool
}
