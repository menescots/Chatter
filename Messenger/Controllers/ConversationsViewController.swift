//
//  ViewController.swift
//  Messenger
//
//  Created by Agata Menes on 07/07/2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class ConversationsViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No conversations."
        label.textAlignment = .center
        label.textColor = UIColor(named: "textColor")
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        setUpTableView()
        startListeningForConversations()
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            print("weak self")
            guard let strongSelf = self else {
                return
            }
            print("inside observer")
            strongSelf.startListeningForConversations()
        })
    }
    
    private func startListeningForConversations(){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            print("no user for email")
            return
        }
        print("listening for confo for user: \(UserDefaults.standard.value(forKey: "email"))")
        
        let currentUserSafeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        DatabaseManager.shared.getAllConversations(for: currentUserSafeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("geting all convo for \(currentUserSafeEmail)")
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                    return
                }
                self?.noConversationLabel.isHidden = true
                self?.tableView.backgroundColor = UIColor(named: "backgroundColor")
                self?.tableView.isHidden = false
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case  .failure(let error):
                self?.tableView.isHidden = true
                self?.noConversationLabel.isHidden = false
                print("failed to get convos: \(error)")
            }
        })
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            let currentConversations = self?.conversations
            
            if let targetConversation = currentConversations?.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAdress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                self?.createNewConversation(result: result)
            }
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = result.email
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            switch result {
            case .success(let conversationID):
                let vc = ChatViewController(with: email, id: conversationID)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: 10,
                                           y: (view.height-100)/2,
                                           width: view.width-20,
                                           height: 100)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            
            present(nav, animated: true)
        }
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.contentView.backgroundColor = UIColor(named: "backgroundColor")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(named: "tabbarColor")
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(withModel: model)
    }
    
    func openConversation(withModel model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let conversationID = conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            DatabaseManager.shared.deleteConversations(withID: conversationID, completion: { success in
                if !success {
                    let ac = UIAlertController(title: "Failed to delete", message: nil, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Ok", style: .default))
                    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    self.present(ac, animated: true)
                }
            })
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
