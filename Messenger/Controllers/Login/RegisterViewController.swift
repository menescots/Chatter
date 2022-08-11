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
    private var isExpand: Bool = false
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
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue // when return is clicked it jumps to password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Enter email adress..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done // when return is clicked it jumps to password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.isSecureTextEntry = true
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0)) //
        field.leftViewMode = .always                                 // setting text in uifield to be 5px away from left
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let registerInButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = UIColor(named: "labelTextColor")
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
        label.textColor = UIColor(named: "labelTextColor")
        return label
    }()
    
    private let passwordSwitch: UISwitch = {
       let passwordSwitch = UISwitch()
        passwordSwitch.isOn = false
        passwordSwitch.onTintColor = UIColor(named: "labelTextColor")
        return passwordSwitch
    }()
    
    private let showPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to show password"
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = UIColor(named: "labelTextColor")
        return label
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle")
        imageView.tintColor = UIColor(named: "labelTextColor")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "backgroundColor")
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        navigationController?.navigationBar.tintColor = UIColor(named: "textColor")
        
        
        // add target
        passwordSwitch.addTarget(self,
                                 action: #selector(passwordSwitchToggled),
                                 for: .touchUpInside)
        registerInButton.addTarget(self,
                              action: #selector(registerButtonTapped),
                              for: .touchUpInside)
        firstNameField.delegate = self
        lastNameField.delegate = self
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
    
    @objc func keyboardAppear(notification:NSNotification) {
        if !isExpand{
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardHeight = keyboardFrame.cgRectValue.height
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.frame.height + keyboardHeight - 50)
            }
            else{
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.frame.height + 200)
            }
            isExpand = true
        }
    }

    @objc func keyboardDisappear(notification:NSNotification) {
        if isExpand{
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardHeight = keyboardFrame.cgRectValue.height
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.frame.height - keyboardHeight - 50)
            }
            else{
                self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.scrollView.frame.height - 200)
            }
            isExpand = false
        }
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
    
    @objc func registerButtonTapped() {
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
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                
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

        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        } else if textField == lastNameField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            registerButtonTapped()
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
        ac.addAction(UIAlertAction(title: "Choose Photo",
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


