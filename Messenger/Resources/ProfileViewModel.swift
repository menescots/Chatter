//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Agata Menes on 11/08/2022.
//

import Foundation

enum ProfileViewModelType {
    case name, email
}

struct ProfileViewModel {
    let profileViewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
