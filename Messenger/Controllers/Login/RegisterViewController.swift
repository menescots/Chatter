//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Agata Menes on 07/07/2022.
//
import JGProgressHUD
import UIKit
import FirebaseAuth
class RegisterViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.black.cgColor
        field.placeholder = "First name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.black.cgColor
        field.placeholder = "Last name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .white
        return field
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
    
    private let registerInButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let photoInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap icon to chose profile picture"
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .systemPink
        return label
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
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle")
        imageView.tintColor = .systemPink
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = UIColor.systemPink
        
        
        // add target
        passwordSwitch.addTarget(self,
                                 action: #selector(passwordSwitchToggled),
                                 for: .touchUpInside)
        registerInButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        // add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerInButton)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(photoInfoLabel)
        scrollView.addSubview(passwordSwitch)
        scrollView.addSubview(showPasswordLabel)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(gesture)
    }
    
    @objc func didTapChangeProfilePic() {
        presentPhotoActionSheet()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 40,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.frame.height/2

        photoInfoLabel.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: imageView.bottom,
                                  width: scrollView.width,
                                 height: 52)
        photoInfoLabel.center.x = self.view.center.x
        photoInfoLabel.textAlignment = .center
        
        firstNameField.frame = CGRect(x: 30,
                                 y: photoInfoLabel.bottom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        
        lastNameField.frame = CGRect(x: 30,
                                 y: firstNameField.bottom+10,
                                  width: scrollView.width-60,
                                 height: 52)
        
        emailField.frame = CGRect(x: 30,
                                 y: lastNameField.bottom+10,
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
        registerInButton.frame = CGRect(x: 30,
                                 y: passwordSwitch.bottom+10,
                                 width: scrollView.width-60,
                                 height: 52)
    }
    
    @objc func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        
        guard let firstName = firstNameField.text,
              let email = emailField.text,
              let lastName = lastNameField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !password.isEmpty,
               password.count >= 6 else {
                allertUserLoginError()
                return
        }
        
        spinner.show(in: view)
        
            // firebase login
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in // check if user is in or not
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                self?.spinner.dismiss(animated: true)
            }
            
            guard !exists else {
                // user already exists
                strongSelf.allertUserLoginError(message: "User with that email already exists.")
                return
            }
            
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    print("Error creating user")
                    return
                }
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAdress: email)
                
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        // upload image
                        guard let image = strongSelf.imageView.image,
                              let data = image.pngData() else {
                            return
                        }
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
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
            
        })
    }
    
    func allertUserLoginError(message: String = "Please enter all information to create an account") {
        let alert = UIAlertController(title: message,
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegisterButton() {
        let vc = RegisterViewController()
        vc.title = "Create account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { // when user tap RETURN/ENTER key
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate { // selecting photo from library or taking new
    
    func presentPhotoActionSheet() {
        let ac = UIAlertController(title: "Profile picture",
                                   message: "Choose a method to add profile picture",
                                   preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil))
        ac.addAction(UIAlertAction(title: "Take Photo",
                                   style: .default,
                                   handler: { [weak self] _ in
            
                                        self?.presentCamera()
        }))
        ac.addAction(UIAlertAction(title: "Chose Photo",
                                   style: .default,
                                   handler: { [weak self] _ in
            
                                        self?.presentPhotoPicker()
        }))
        present(ac, animated: true)
    }
    
    func presentCamera()  {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        } //chosen pic

        self.imageView.image = selectedImage
    
    }
}


