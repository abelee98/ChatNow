//
//  Message.swift
//  ChatNow
//
//  Created by Abraham Lee on 5/19/18.
//  Copyright © 2018 Abraham Lee. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromID: String?
    var text: String?
    var timeStamp: NSNumber?
    var toID: String?
    
    var imageURL: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    var imageSentText: String?
    
    func chatPartnerID() -> String?{
        return fromID == Firebase.Auth.auth().currentUser?.uid ? toID : fromID
    }
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromID = dictionary["fromID"] as? String
        text = dictionary["text"] as? String
        timeStamp = dictionary["timeStamp"] as? NSNumber
        toID = dictionary["toID"] as? String
        
        imageURL = dictionary["imageURL"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageSentText = dictionary["imageSentText"] as? String
    }
    
}

