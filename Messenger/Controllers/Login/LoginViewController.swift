//
//  LoginViewController.swift
//  Messenger
//
//  Created by Agata Menes on 07/07/2022.
//

import UIKit

class LoginViewController: UIViewController {

    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "images")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Login"
        view.backgroundColor = .white

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapRegisterButton))
        
        // add subviews
        view.addSubview(imageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = view.frame.size.width/2
        imageView.frame = CGRect(x: (view.frame.size.width-size)/2,
                                 y: 140,
                                 width: size,
                                 height: size)
    }
    @objc private func didTapRegisterButton() {
        let vc = RegisterViewController()
        vc.title = "Create account"
        navigationController?.pushViewController(vc, animated: true)
    }
}
