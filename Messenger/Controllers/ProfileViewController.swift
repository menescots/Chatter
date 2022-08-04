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

enum ProfileViewModelType {
    case name, email
}

struct ProfileViewModel {
    let profileViewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

class ProfileViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    var data = [ProfileViewModel]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileTableViewCell.self,
                           forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        data.append(ProfileViewModel(profileViewModelType: .name,
                                     title: UserDefaults.standard.value(forKey: "name") as? String ?? "No name",
                                     handler: nil))
        data.append(ProfileViewModel(profileViewModelType: .email,
                                     title: UserDefaults.standard.value(forKey: "email") as? String ?? "No email",
                                     handler: nil))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    @IBAction func logOutButton(_ sender: Any) {
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
                nav.navigationBar.tintColor = .systemBackground
                
                strongSelf.present(nav, animated: true)
            } catch {
                print("Failed to log out.")
            }
        }))
        present(actionSheet, animated: true)
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        let filename = safeEmail + "_profile_picture.png"
        
        let path = "images/" + filename
        
        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .systemBackground
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150)/2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
    
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.layer.masksToBounds = true
        headerView.addSubview(imageView)
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("failed to download URL \(error)")
            }
        })
        return headerView
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true )
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.profileViewModelType {
        case .name:
            self.textLabel?.textColor = UIColor.label
            self.textLabel?.textAlignment = .center
            self.textLabel?.font = UIFont.systemFont(ofSize: 30)
        case .email:
            self.textLabel?.textColor = UIColor.label
            self.textLabel?.textAlignment = .center
            self.textLabel?.font = UIFont.systemFont(ofSize: 15)
        }
    }
}
