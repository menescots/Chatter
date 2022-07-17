//
//  LoginViewController.swift
//  Messenger
//
//  Created by Agata Menes on 07/07/2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD
class LoginViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let passwordSwitch: UISwitch = {
       let passwordSwitch = UISwitch()
        passwordSwitch.isOn = false
        passwordSwitch.onTintColor = .lightGray
        return passwordSwitch
    }()
    
    private let showPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to show password"
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .systemPink
        return label
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue // when return is clicked it jumps to password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.black.cgColor
        field.placeholder = "Enter email adress..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done // when return is clicked it jumps to password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.black.cgColor
        field.placeholder = "Password..."
        field.isSecureTextEntry = true
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .white
        return field
    }()
    
    private let logInButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .systemPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let pushToRegisterButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "message")
        imageView.tintColor = .systemPink
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.layer.cornerRadius = 20
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = UIColor.systemPink
        
        // add target
        logInButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        pushToRegisterButton.addTarget(self,
                                       action: #selector(pushToRegisterButtonTapped),
                                       for: .touchUpInside)
        passwordSwitch.addTarget(self,
                                 action: #selector(passwordSwitchToggled),
                                 for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        fbLoginButton.delegate = self
        
        // add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(logInButton)
        scrollView.addSubview(pushToRegisterButton)
        scrollView.addSubview(passwordSwitch)
        scrollView.addSubview(showPasswordLabel)
        scrollView.addSubview(fbLoginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 50,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                 y: imageView.bottom+50,
                                  width: scrollView.width-60,
                                 height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                 y: emailField.bottom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        
        passwordSwitch.frame = CGRect(x: 30,
                                 y: passwordField.bottom+10,
                                 width: scrollView.width-60,
                                 height: 52)
        showPasswordLabel.frame = CGRect(x: passwordSwitch.right+10,
                                 y: passwordField.bottom,
                                 width: scrollView.width-60,
                                 height: 52)
        logInButton.frame = CGRect(x: 30,
                                 y: passwordSwitch.bottom+10,
                                 width: scrollView.width-60,
                                 height: 52)
        pushToRegisterButton.frame = CGRect(x: 30,
                                 y: logInButton.bottom+10,
                                 width: scrollView.width-60,
                                 height: 52)
        
        fbLoginButton.frame = CGRect(x: 30,
                                   y: pushToRegisterButton.bottom+30,
                                   width: scrollView.width-60,
                                   height: 52)

    }
    
    @objc func passwordSwitchToggled() {
        if passwordSwitch.isOn {
            showPasswordLabel.text = "Hide password"
            passwordField.isSecureTextEntry = false
        } else {
            showPasswordLabel.text = "Show password"
            passwordField.isSecureTextEntry = true
        }
    }
    
    @objc func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            allertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
            // firebase login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                self?.spinner.dismiss(animated: true)
            }
            
            guard let result = authResult, error == nil else {
               print("failed to log in with email: \(email)")
                return
            }
            
            let user = result.user
            // saving user email
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Logged in: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc func pushToRegisterButtonTapped() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func allertUserLoginError() {
        let alert = UIAlertController(title: "Incorrect email or password",
                                      message: "Please double-check and try again",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel))
        
        present(alert, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { // when user tap RETURN/ENTER key
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            print("user failder to log in with facebook")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":
                                                                        "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: { connection, result, error in
            guard let result = result as? [String: Any],
                    error == nil else {
                print("Failed to make facebook graph reqquest")
                return
            }
           
            print(result)

            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("failed to get email and name from fb results print \(result)")
                return
            }
            //saving email form facebook
            
            UserDefaults.standard.set(email, forKey: "email")
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAdress: email)
                
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard let url = URL(string: pictureUrl) else { return }
                            print("Downloading bits from facebook image")
                           let task = URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                                guard let data = data else {
                                    print("Failed to download data from facebook")
                                    return
                                }
                                
                                print("got data from fb, uploading..")
                                
                                // upload image
                                let filename = chatUser.profilePicutreFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                        
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                                
                            })
                            task.resume()
                        }
                    })}
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                
                guard let strongSelf = self else { return }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("mfa may be neded \(error)")
                    }
                    return
                }
                print("successfully log in with facebook")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
        
    }
}
