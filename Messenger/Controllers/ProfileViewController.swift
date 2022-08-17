//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Agata Menes on 07/07/2022.
//
import FirebaseAuth
import UIKit
import FBSDKLoginKit
import SDWebImage
import SwiftUI

final class ProfileViewController: UIViewController {
    private var loginObserver: NSObjectProtocol?
    
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 75
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor(named: "labelTextColor")?.cgColor
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .light)
        label.textColor = UIColor(named: "labelTextColor")
        return label
    }()
    
    private let emailNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .light)
        label.textColor = UIColor(named: "labelTextColor")
        return label
    }()
    private let logOutButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log Out", for: .normal)
        button.backgroundColor = UIColor(named: "labelTextColor")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .light)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "backgroundColor")
        getImageForProfile()
        setEmailAndName()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.getImageForProfile()
            strongSelf.setEmailAndName()
        })
        view.addSubview(imageView)
        view.addSubview(nameLabel)
        view.addSubview(emailNameLabel)
        view.addSubview(logOutButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = view.width/3
        imageView.frame = CGRect(x: (view.width-size)/2,
                                 y: self.view.top+200,
                                 width: 150,
                                 height: 150)
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.center.x = self.view.center.x
        nameLabel.frame = CGRect(x: (view.width-size)/2,
                                 y: imageView.bottom+20,
                                  width: view.width,
                                 height: 52)
        nameLabel.center.x = self.view.center.x
        nameLabel.textAlignment = .center
        
        emailNameLabel.frame = CGRect(x: (view.width-size)/2,
                                 y: nameLabel.bottom+5,
                                  width: view.width,
                                 height: 52)
        emailNameLabel.center.x = self.view.center.x
        emailNameLabel.textAlignment = .center
        
        logOutButton.frame = CGRect(x: (view.width-size)/2,
                                    y: self.view.bottom-170,
                                  width: 120,
                                 height: 40)
        logOutButton.center.x = self.view.center.x
        logOutButton.contentHorizontalAlignment = .center
    }
    
    @IBAction func logOutButton(_ sender: Any) {
        UserDefaults.standard.setValue(nil, forKey: "email")
        UserDefaults.standard.setValue(nil, forKey: "name")
        UserDefaults.standard.setValue(nil, forKey: "profile_picture_url")
        logOutUser()
    }

   @objc func logOutUser() {
        let actionSheet = UIAlertController(title: "Do you want to log out?",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Log out",
                                      style: .destructive,
                                      handler: { [weak self] _ in
            
            guard let strongSelf = self else { return }
            
            FBSDKLoginKit.LoginManager().logOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                nav.navigationBar.tintColor = UIColor(named: "backgroundColor")
                
                strongSelf.present(nav, animated: true)
            } catch {
                print("Failed to log out.")
            }
        }))
        present(actionSheet, animated: true)
    }
    func getImageForProfile(){
        print("poczontek zdjecnia")
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        let filename = safeEmail + "_profile_picture.png"
        
        let path = "images/" + filename
        
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                self.imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("failed to download URL \(error)")
            }
        })
    }
    
    func setEmailAndName(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("no email")
            return
        }
        guard let name = UserDefaults.standard.value(forKey: "name") as? String else {
            print("no name")
            return
        }
        nameLabel.text = name
        emailNameLabel.text = email
    }
}


