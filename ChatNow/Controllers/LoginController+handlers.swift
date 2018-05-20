//
//  LoginController+handlers.swift
//  ChatNow
//
//  Created by Abraham Lee on 5/19/18.
//  Copyright © 2018 Abraham Lee. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // segue into image picker
    @objc func handleImageSelect() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    // picking user profile image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] {
            selectedImageFromPicker = editedImage as? UIImage
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] {
            selectedImageFromPicker = originalImage as? UIImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImage.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    // in case they cancelled picking an image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        print("cancel")
    }
    
    // registering a new user
    func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password, completion: {(user: User?, error) in
            if error != nil {
                print("Error Authenticating", error)
                return
            }
            // success
            print("success")
            guard let uid = user?.uid else {
                return
            }
            
            // profile image
            let imageName = NSUUID().uuidString
            let storage = Storage.storage().reference().child("profile_images").child("\(imageName)")
            
            if let profileImages = self.profileImage.image, let uploadData = UIImageJPEGRepresentation(profileImages, 0.1) {
                
                storage.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil {
                        
                        print(error!)
                        return
                    }
                    
                    if let profileImages = metadata?.downloadURL()?.absoluteString {
                        
                        let values = ["name": name, "email": email, "profileImage": profileImages, "id": uid]
                        
                        self.registerUserWithID(uid: uid, values: values as [String : AnyObject])
                    }
                })
            }
            
        })
        
    }
    
    // finally registering with picture
    private func registerUserWithID(uid: String, values: [String: AnyObject]) {
        let ref = Database.database().reference()
        let currentRef = ref.child("users").child(uid)
        
        currentRef.updateChildValues(values, withCompletionBlock: {(error, ref) in
            if error != nil {
                print("Error Saving")
                return
            }
            
            let user = Users()
            user.id = values["id"] as? String
            user.email = values["email"] as? String
            user.profileImage = values["profileImage"] as? String
            user.name = values["name"] as? String
            self.messagesController?.setUpNavBarWithUser(user: user)
            
            self.dismiss(animated: true, completion: nil)
            
        })
    }
    
    
}

