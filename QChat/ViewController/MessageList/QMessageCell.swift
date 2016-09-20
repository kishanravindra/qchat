//
//  QMessageCell.swift
//  QChat
//
//  Created by Kishan Ravindra on 17/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
class QMessageCell: UICollectionViewCell{
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var outgoingmessageBgView: UIView!
    @IBOutlet weak var incomingmessageBgView: UIView!
    
    @IBOutlet weak var outgoingMessagesLabel: UILabel!
    @IBOutlet weak var incomingMessagesLabel: UILabel!
    
    @IBOutlet weak var outgoingCellViewWidth: NSLayoutConstraint!
    @IBOutlet weak var incomingCellViewWidth: NSLayoutConstraint!
    
    var messageChats:Messages?{
        didSet{
            let widthOfCell = QHelper.sharedHelper.calculateCollectionCellHeightForText(messageChats!.messageText!).width + 32
            //Outgoing chats
            if messageChats?.senderId == FIRAuth.auth()?.currentUser?.uid
            {
               incomingmessageBgView.hidden = true
               outgoingmessageBgView.hidden = false
               profileImage.hidden = true
               outgoingmessageBgView.backgroundColor = UIColor(red: 0.22, green: 0.74, blue: 0.62, alpha: 1)
               outgoingMessagesLabel.text = messageChats?.messageText
              outgoingCellViewWidth.constant = widthOfCell
            }else{
                //Incoming chats
                outgoingmessageBgView.hidden = true
                incomingmessageBgView.hidden = false
                profileImage.hidden = false
                incomingmessageBgView.backgroundColor = UIColor(red: 0.46, green: 0.16, blue: 0.46, alpha: 1)
                incomingMessagesLabel.text = messageChats?.messageText
                incomingCellViewWidth.constant = widthOfCell
            }
        }
    }
}
