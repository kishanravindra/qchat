//
//  Messages.swift
//  QChat
//
//  Created by Kishan Ravindra on 15/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
class Messages: NSObject {
    var messageText:String?
    var receiverId:String?
    var senderId:String?
    var timeStamp:NSNumber?
    var chatImageUrl:String?
    var chatImageWidth: NSNumber?
    var chatImageHeight: NSNumber?
    
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        senderId = dictionary["senderId"] as? String
        messageText = dictionary["messageText"] as? String
        timeStamp = dictionary["timeStamp"] as? NSNumber
        receiverId = dictionary["receiverId"] as? String
        
        chatImageUrl = dictionary["chatImageUrl"] as? String
        chatImageWidth = dictionary["chatImageWidth"] as? NSNumber
        chatImageHeight = dictionary["chatImageHeight"] as? NSNumber
    }
    
    
    func checkForFromId()->String?
    {
        return senderId == FIRAuth.auth()?.currentUser?.uid  ? receiverId : senderId
    }
}
