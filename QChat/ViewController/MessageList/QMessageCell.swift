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
    
    @IBOutlet weak var outgoingImage: UIImageView!
    @IBOutlet weak var incomingImage: UIImageView!
    @IBOutlet weak var outgoingMessagesLabel: UILabel!
    @IBOutlet weak var incomingMessagesLabel: UILabel!
    
    @IBOutlet weak var outgoingCellViewWidth: NSLayoutConstraint!
    @IBOutlet weak var incomingCellViewWidth: NSLayoutConstraint!
    var widthOfCell:CGFloat?
    var messageChats:Messages?{
        didSet{
          
            //Outgoing chats
            if messageChats?.senderId == FIRAuth.auth()?.currentUser?.uid
            {
               incomingmessageBgView.hidden = true
               outgoingmessageBgView.hidden = false
               profileImage.hidden = true
               outgoingmessageBgView.backgroundColor = UIColor(red: 0.22, green: 0.74, blue: 0.62, alpha: 1)
               outgoingMessagesLabel.text = messageChats?.messageText
                setWidthConstraintForIncomingOutGoingMessage(outgoingCellViewWidth)
                displayChatImage(outgoingImage,chatView: outgoingmessageBgView)
            }else{
                //Incoming chats
                outgoingmessageBgView.hidden = true
                incomingmessageBgView.hidden = false
                profileImage.hidden = false
                incomingmessageBgView.backgroundColor = UIColor(red: 0.46, green: 0.16, blue: 0.46, alpha: 1)
                incomingMessagesLabel.text = messageChats?.messageText
                setWidthConstraintForIncomingOutGoingMessage(incomingCellViewWidth)
                displayChatImage(incomingImage,chatView: incomingmessageBgView)

            }
        }
    }
    
    
    private func displayChatImage(chatImageView:UIImageView,chatView:UIView){
        if let imageUrl = messageChats?.chatImageUrl{
            chatImageView.loadImageUsingCacheWithUrlString(imageUrl)
            chatImageView.hidden = false
            chatView.backgroundColor = .clearColor()
        }else{
            chatImageView.hidden = true
        }
    }
    
    private func setWidthConstraintForIncomingOutGoingMessage(widthConstraint:NSLayoutConstraint){
        if let messageText = messageChats?.messageText{
            widthConstraint.constant = QHelper.sharedHelper.calculateCollectionCellHeightForText(messageText).width + 32
        } else if messageChats?.chatImageUrl != nil{
            widthConstraint.constant = 200 //setting some initial constant width
        }
    }
}
