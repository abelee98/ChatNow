//
//  ChatLogController.swift
//  ChatNow
//
//  Created by Abraham Lee on 5/19/18.
//  Copyright © 2018 Abraham Lee. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let cellID = "cellID"
    var messages = [Message]()
    
    var user: Users? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid, let toID = user?.id else {
            return
        }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toID)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                self.messages.append(Message(dictionary: dictionary))
                DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
                    
                    let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                })
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    lazy var inputTextField: UITextField = {
        let inputText = UITextField()
        
        inputText.placeholder = "Enter Message..."
        inputText.translatesAutoresizingMaskIntoConstraints = false
        inputText.delegate = self
        
        return inputText
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.alwaysBounceVertical = true
        collectionView?.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellID)
        
        collectionView?.keyboardDismissMode = .interactive
        
        // apple way of doing this
        
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        let pictureButton = UIImageView()
        pictureButton.image = UIImage(named: "stacks")
        pictureButton.isUserInteractionEnabled = true
        pictureButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleImage)))
        pictureButton.translatesAutoresizingMaskIntoConstraints = false
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        containerView.addSubview(pictureButton)
        
        // constraints
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // constraints
        pictureButton.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        pictureButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        pictureButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        pictureButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        
        containerView.addSubview(self.inputTextField)
        
        // constraints
        self.inputTextField.leftAnchor.constraint(equalTo: pictureButton.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let seperatorLine = UIView()
        
        seperatorLine.backgroundColor = UIColor.lightGray
        seperatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(seperatorLine)
        
        // constraints
        seperatorLine.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        seperatorLine.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        seperatorLine.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        seperatorLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        return containerView
    }()
    
    @objc func handleImage() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] {
            selectedImageFromPicker = editedImage as? UIImage
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] {
            selectedImageFromPicker = originalImage as? UIImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadImageToFirebase(image: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadImageToFirebase(image: UIImage) {
        let imageName = NSUUID().uuidString
        let storage = Storage.storage().reference().child("message_images").child("\(imageName)")
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.1) {
            storage.putData(uploadData, metadata: nil, completion: { (meta, error) in
                if error != nil {
                    print(error!)
                    return
                }
                if let imageURL = meta?.downloadURL()?.absoluteString {
                    self.sendMessageWithImage(imageURL: imageURL, image: image)
                }
            })
        }
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleKeyboardWillShow(notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]
        containerViewBottomAnchor?.constant = -(keyboardFrame?.height)!
        
        UIView.animate(withDuration: duration! as! TimeInterval) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handleKeyboardWillHide(notification: Notification) {
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: duration! as! TimeInterval) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        //modify bubbleview width
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageURL != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.bubbleView.backgroundColor = UIColor.clear
            cell.textView.isHidden = true
        }
        
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        if let messageURL = message.imageURL {
            cell.messageImageView.loadImageUsingCacheWithString(urlString: messageURL)
        }
        
        if let profileImageURL = self.user?.profileImage {
            cell.profileImageView.loadImageUsingCacheWithString(urlString: profileImageURL)
        }
        
        if message.fromID == Firebase.Auth.auth().currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            cell.bubbleLeftAnchor?.isActive = false
            cell.bubbleRightAnchor?.isActive = true
        } else {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.bubbleLeftAnchor?.isActive = true
            cell.bubbleRightAnchor?.isActive = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        let width = UIScreen.main.bounds.width
        let message = messages[indexPath.item]
        
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    @objc func handleSend() {
        let properties = ["text": inputTextField.text!] as [String : AnyObject]
        
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithImage(imageURL: String, image: UIImage) {
        let imageSentText = "Sent an image :)"
        let properties = ["imageURL": imageURL, "imageHeight": image.size.height, "imageWidth": image.size.width, "imageSentText": imageSentText] as [String: AnyObject]
        
        sendMessageWithProperties(properties: properties)
        
    }
    
    private func sendMessageWithProperties(properties: [String : AnyObject]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toID = user!.id
        let fromID = Firebase.Auth.auth().currentUser?.uid
        let timestamp = Int(NSDate().timeIntervalSince1970)
        var values = ["toID": toID!, "fromID": fromID!, "timeStamp": timestamp] as [String : Any]
        
        //appending properties to values
        //key, $0; value, $1
        
        properties.forEach({values[$0] = $1})
        
        self.inputTextField.text = nil
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error ?? "Something went wrong")
                return
            }
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromID!).child(toID!)
            
            let messageID = childRef.key
            userMessageRef.updateChildValues([messageID: 1])
            
            let recipientRef = Database.database().reference().child("user-messages").child(toID!).child(fromID!)
            recipientRef.updateChildValues([messageID: 1])
            
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    var startingFrame: CGRect?
    var blackBackground: UIView?
    var imageView: UIImageView?
    
    
    //zooming option
    func performImageZoom(imageView: UIImageView) {
        self.imageView = imageView
        self.imageView?.isHidden = true
        
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        
        let zoomingFrame = UIImageView(frame: startingFrame!)
        zoomingFrame.backgroundColor = UIColor.red
        zoomingFrame.image = imageView.image
        zoomingFrame.translatesAutoresizingMaskIntoConstraints = false
        zoomingFrame.isUserInteractionEnabled = true
        zoomingFrame.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackground = UIView()
            blackBackground?.translatesAutoresizingMaskIntoConstraints = false
            blackBackground?.backgroundColor = UIColor.black
            blackBackground?.alpha = 0
            
            keyWindow.addSubview(blackBackground!)
            
            // constraints
            blackBackground?.leftAnchor.constraint(equalTo: (collectionView?.leftAnchor)!).isActive = true
            blackBackground?.bottomAnchor.constraint(equalTo: (collectionView?.bottomAnchor)!).isActive = true
            blackBackground?.widthAnchor.constraint(equalTo: (collectionView?.widthAnchor)!).isActive = true
            blackBackground?.heightAnchor.constraint(equalTo: (collectionView?.heightAnchor)!).isActive = true
            
            keyWindow.addSubview(zoomingFrame)
            
            let height = (self.startingFrame?.height)! / (self.startingFrame?.width)! * keyWindow.frame.width
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomingFrame.centerXAnchor.constraint(equalTo: (self.collectionView?.centerXAnchor)!).isActive = true
                zoomingFrame.centerYAnchor.constraint(equalTo: (self.collectionView?.centerYAnchor)!).isActive = true
                zoomingFrame.widthAnchor.constraint(equalToConstant: keyWindow.frame.width).isActive = true
                zoomingFrame.heightAnchor.constraint(equalToConstant: height).isActive = true
                self.blackBackground?.alpha = 1
                self.inputContainerView.alpha = 0
                
                zoomingFrame.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        let zoomOutImageView = tapGesture.view
        zoomOutImageView?.layer.cornerRadius = 16
        zoomOutImageView?.layer.masksToBounds = true
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            zoomOutImageView?.frame = self.startingFrame!
            self.blackBackground?.alpha = 0
            self.inputContainerView.alpha = 1
        }) { (completed: Bool) in
            zoomOutImageView?.removeFromSuperview()
            self.imageView?.isHidden = false
        }
    }
}


