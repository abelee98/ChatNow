//
//  ViewController.swift
//  ChatNow
//
//  Created by Abraham Lee on 5/19/18.
//  Copyright © 2018 Abraham Lee. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class MessagesController:  UITableViewController {
    
    var messages = [Message]()
    var messagesDicitonary = [String: Message]()
    let cellID = "cellid"
    var reloadDataCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(handleLogout))
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        tableView.allowsSelectionDuringEditing = true
        
        
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        print("deleted")
        let uid = Auth.auth().currentUser?.uid
        let message = messages[indexPath.row]
        
        if let chatPartnerID = message.chatPartnerID() {
            Database.database().reference().child("user-messages").child(uid!).child(chatPartnerID).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print("Failed to delete, ", error!)
                    return
                }
                
                self.messagesDicitonary.removeValue(forKey: chatPartnerID)
                self.attempReload()
            })
        }
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            self.messagesDicitonary.removeValue(forKey: snapshot.key)
            self.attempReload()
        }, withCancel: nil)
    }
    
    fileprivate func fetchMessageWithMessageId(_ messageId: String) {
        let messagesReference = Database.database().reference().child("messages").child(messageId)
        
        messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(dictionary: dictionary)
                
                if let chatPartnerId = message.chatPartnerID() {
                    self.messagesDicitonary[chatPartnerId] = message
                }
                
                self.attempReload()
            }
            
        }, withCancel: nil)
    }
    
    private func attempReload() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadData), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    @objc func handleReloadData() {
        self.messages = Array(self.messagesDicitonary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            
            return (message1.timeStamp?.int32Value)! > (message2.timeStamp?.int32Value)!
        })
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        guard let chatPartnerID = message.chatPartnerID() else {return}
        
        let ref = Database.database().reference().child("users").child(chatPartnerID)
        ref.observe(.value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject]
                else {
                    return
            }
            
            let user = Users()
            user.id = chatPartnerID
            user.email = dictionary["email"] as? String
            user.profileImage = dictionary["profileImage"] as? String
            user.name = dictionary["name"] as? String
            self.showChatControllerForUser(user: user)
            
        }, withCancel: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UserCell
        
        let messageTexts = messages[indexPath.row]
        
        cell.message = messageTexts
        
        if let imageText = cell.message?.imageSentText {
            cell.detailTextLabel?.text = imageText
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    @objc func handleNewMessage() {
        let newMessage = NewMessageController()
        newMessage.messagesController = self
        let navController = UINavigationController(rootViewController: newMessage)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        
        Firebase.Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if ((user) != nil) {
                self.fetchUserAndSetUpNavBar()
            } else {
                self.handleLogout()
                print("not logged in")
            }
        }
        
    }
    
    func fetchUserAndSetUpNavBar() {
        
        guard let uid = Firebase.Auth.auth().currentUser?.uid else {
            // for some reason, uid is nil
            return
        }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: String] {
                let user = Users()
                user.id = dictionary["id"]
                user.email = dictionary["email"]
                user.profileImage = dictionary["profileImage"]
                user.name = dictionary["name"]
                self.setUpNavBarWithUser(user: user)
                
            }
            
        }, withCancel: nil)
    }
    
    func setUpNavBarWithUser(user: Users) {
        messages.removeAll()
        messagesDicitonary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints =  false
        titleView.addSubview(containerView)
        
        // profile image on top of messages
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        
        // getting the image from cache
        if let profileImageURL = user.profileImage {
            profileImageView.loadImageUsingCacheWithString(urlString: profileImageURL)
        }
        
        containerView.addSubview(profileImageView)
        
        // ios 9 constraints (need x, y, width, height)
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // putting in name
        let nameLabelView = UILabel()
        nameLabelView.text = user.name
        nameLabelView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabelView)
        
        
        // need x, y, width, height
        nameLabelView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabelView.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabelView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabelView.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
    }
    
    func showChatControllerForUser(user: Users) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    @objc func handleLogout() {
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }
    
}

