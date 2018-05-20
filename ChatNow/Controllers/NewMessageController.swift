//
//  NewMessageController.swift
//  ChatNow
//
//  Created by Abraham Lee on 5/19/18.
//  Copyright © 2018 Abraham Lee. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        
        fetchUser()
    }
    
    let cellID = "cellid"
    var users = [Users]()
    
    func fetchUser() {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: String] {
                if snapshot.key != Auth.auth().currentUser?.uid {
                    let user = Users()
                    user.id = snapshot.key
                    user.email = dictionary["email"]
                    user.profileImage = dictionary["profileImage"]
                    user.name = dictionary["name"]
                    self.users.append(user)
                }
            }
            
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            print(snapshot)
        }, withCancel: nil)
    }
    
    @objc func handleCancel() {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as? UserCell
        
        
        let user = users[indexPath.row]
        cell?.textLabel?.text = user.name
        cell?.detailTextLabel?.text = user.email
        
        if let profileImageURL = user.profileImage {
            cell?.profileImageView.loadImageUsingCacheWithString(urlString: profileImageURL)
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let user = users[indexPath.row]
        print(user.name ?? "")
        
        dismiss(animated: true, completion: nil)
        self.messagesController?.showChatControllerForUser(user: user)
        
    }
    
    
}
