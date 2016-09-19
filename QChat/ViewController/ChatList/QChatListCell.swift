//
//  QChatListCell.swift
//  QChat
//
//  Created by Kishan Ravindra on 15/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase

class QChatListCell: UITableViewCell {
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var messageText: UILabel!
    @IBOutlet weak var timeStamp: UILabel!
    var messageList:Messages? {
        didSet{
            messageText.text = messageList?.messageText
            if let messageDate = messageList?.timeStamp?.doubleValue{
                timeStamp.text = QHelper.sharedHelper.formatDate(messageDate)
            }
            
            //Getting the username from the sender id. We will access the user name from the User DB and passing the child node as 'ID'. which will returns as a name.
            
            if let senderUserNameFromId = messageList?.checkForFromId()
            {
                print(senderUserNameFromId)
                let senderRef = FIRDatabase.database().reference().child(kUser).child(senderUserNameFromId)
                senderRef.observeSingleEventOfType(.Value, withBlock:
                    { (result) in
                        if let senderDict = result.value as? [String:AnyObject]
                        {
                            self.userName.text = senderDict["name"] as? String
                            if let userImageUrl = senderDict["profileImageUrl"] as? String{
                               self.profileImage.loadImageUsingCacheWithUrlString(userImageUrl)
                            }
                        }
                    }, withCancelBlock: nil)
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
