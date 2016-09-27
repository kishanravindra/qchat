//
//  QMessageCell.swift
//  QChat
//
//  Created by Kishan Ravindra on 17/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class QMessageCell: UICollectionViewCell{
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var outgoingmessageBgView: UIView!
    @IBOutlet weak var incomingmessageBgView: UIView!
    
    @IBOutlet weak var outgoingImage: UIImageView!
    @IBOutlet weak var incomingImage: UIImageView!
    @IBOutlet weak var outgoingMessagesLabel: UILabel!
    @IBOutlet weak var incomingMessagesLabel: UILabel!
    
    @IBOutlet weak var outgoingActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var incomingActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var incomingPlayBtn: UIButton!
    @IBOutlet weak var outgoingPlayBtn: UIButton!
    
    @IBOutlet weak var outgoingCellViewWidth: NSLayoutConstraint!
    @IBOutlet weak var incomingCellViewWidth: NSLayoutConstraint!
    var messageListVc:QMessagesListController?
    var widthOfCell:CGFloat?
    var videoPlayerLayer: AVPlayerLayer?
    var videoPlayer: AVPlayer?
    var videoChatBgView = UIView()
    var videoActivityIndicator = UIActivityIndicatorView()
    var videoPlayBtn = UIButton()
    var messageChats:Messages?{
        didSet{
          
            //Outgoing chats
            if messageChats?.senderId == FIRAuth.auth()?.currentUser?.uid
            {
               setVideoPlayerReference(outgoingPlayBtn, activityIndicator: outgoingActivityIndicator, videoBgView: outgoingmessageBgView)
                
               hidePlayBtn(outgoingPlayBtn,activityIndicator: outgoingActivityIndicator)
               incomingmessageBgView.hidden = true
               outgoingmessageBgView.hidden = false
               profileImage.hidden = true
               outgoingmessageBgView.backgroundColor = UIColor(red: 0.22, green: 0.74, blue: 0.62, alpha: 1)
                outgoingMessagesLabel.text = messageChats?.messageText
                
                setWidthConstraintForIncomingOutGoingMessage(outgoingCellViewWidth)
                displayChatImage(outgoingImage,chatView: outgoingmessageBgView)
            }else{
                //Incoming chats
                setVideoPlayerReference(incomingPlayBtn, activityIndicator: incomingActivityIndicator, videoBgView: incomingmessageBgView)

                hidePlayBtn(incomingPlayBtn,activityIndicator: incomingActivityIndicator)
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
        chatImageView.userInteractionEnabled = true
        chatImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomSelectedChatImage)))
    }
    
    private func setWidthConstraintForIncomingOutGoingMessage(widthConstraint:NSLayoutConstraint){
        if let messageText = messageChats?.messageText{
            widthConstraint.constant = QHelper.sharedHelper.calculateCollectionCellHeightForText(messageText).width + 32
        } else if messageChats?.chatImageUrl != nil{
            widthConstraint.constant = 200 //setting some initial constant width
        }
    }
    
    private func hidePlayBtn(playBtn:UIButton,activityIndicator:UIActivityIndicatorView){
        guard messageChats?.videoUrl != nil else{
            playBtn.hidden = true
            activityIndicator.hidden = true
            return
        }
        playBtn.hidden = false
        activityIndicator.hidden = true
        playBtn.addTarget(self, action: #selector(QMessageCell.playChatVideo(_:)), forControlEvents: .TouchUpInside)
    }
    
    
    private func setVideoPlayerReference(playBtn:UIButton,activityIndicator:UIActivityIndicatorView,videoBgView:UIView){
        videoPlayBtn = playBtn
        videoActivityIndicator = activityIndicator
        videoChatBgView = videoBgView
    }
    
    //MARK:- PlayVideo
    func playChatVideo(sender:UIButton){
        print("Play Video")
        print(videoChatBgView)
        if let videoUrlString = messageChats?.videoUrl ,chatVideoUrl = NSURL(string: videoUrlString){
            print(chatVideoUrl)
            videoPlayer = AVPlayer(URL: chatVideoUrl)
            if let chatVideoPlayerBg:UIView = videoChatBgView{
                videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
                videoPlayerLayer?.frame = chatVideoPlayerBg.bounds
                videoPlayerLayer?.cornerRadius = 12
                videoPlayerLayer?.masksToBounds = true
                chatVideoPlayerBg.layer.addSublayer(videoPlayerLayer!)
                videoPlayer?.play()
                videoActivityIndicator.startAnimating()
                videoActivityIndicator.hidden = false
                videoPlayBtn.hidden = true
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        videoPlayerLayer?.removeFromSuperlayer()
        videoPlayer?.pause()
        videoActivityIndicator.stopAnimating()
    }
    
    func zoomSelectedChatImage(tapGesture:UITapGestureRecognizer){        
        if messageChats?.videoUrl != nil{
            return
        }
        
        if let imageView = tapGesture.view as? UIImageView {
            self.messageListVc?.startZoomingChatMessageImageView(imageView)
        }
    }
}
