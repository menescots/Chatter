//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Agata Menes on 25/07/2022.
//

import UIKit
import SwiftUI
import SDWebImage

class ConversationTableViewCell: UITableViewCell {

    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 37.5
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .semibold)
        label.textColor = UIColor(named: "textColor")
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(named: "textColor")
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 13,
                                     width: 75,
                                     height: 75)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 13,
                                     y: 10,
                                     width: contentView.width-20-userImageView.width,
                                     height: (contentView.height-30)/2)
        
        userMessageLabel.frame = CGRect(x: userImageView.right + 13,
                                        y: userNameLabel.bottom+2,
                                     width: contentView.width-50-userImageView.width,
                                     height: (contentView.height-10)/2)
    }
    
    public func configure(with model: Conversation){
        userMessageLabel.text = model.latestMessage.message
        userNameLabel.text = model.name
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
    }
}
