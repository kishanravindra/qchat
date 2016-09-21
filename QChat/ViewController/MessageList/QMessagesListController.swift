//
//  QMessagesListController.swift
//  QChat
//
//  Created by Kishan Ravindra on 14/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase

class QMessagesListController: UIViewController,UITextViewDelegate {
    
     //IBOutlets
    @IBOutlet weak var selectedUserProfileImage: UIImageView!
    @IBOutlet weak var selectedUserName: UILabel!
    @IBOutlet weak var inputMessageTextField: SAMTextView!
    @IBOutlet weak var chatActionView: UIView!
    @IBOutlet weak var messagesCollectionView: UICollectionView!
    
   
    //NSLayoutConstraint
    @IBOutlet weak var chatViewBottonConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTextHeightConstriant: NSLayoutConstraint!
    
    var user: Users?
    var messages = [Messages]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpInitialNavBar()
        loadMessageConversation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        inputMessageTextField.setContentOffset(CGPoint.zero, animated: false)
    }
    
    //Button Actions
    //MARK:- Back Button Action
    @IBAction func backBtnPressed(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK:- Send Button Action
    @IBAction func messageSendBtnPressed(sender: AnyObject)
    {
                let messageRef = FIRDatabase.database().reference().child(kMessages)
                //Generating unique id for each message, which user sends.
                let messagechildIdRef = messageRef.childByAutoId()
                //We will the map the message to recipient user with his account id.
                let receiverUserId = user!.id!
                //Sender id
                let senderUserId = FIRAuth.auth()!.currentUser!.uid
                let timestamp: NSNumber = Int(NSDate().timeIntervalSince1970)
                let values = ["messageText": inputMessageTextField.text!, "receiverId": receiverUserId, "senderId": senderUserId, "timeStamp": timestamp]
        
                messagechildIdRef.updateChildValues(values) { (error, ref) in
                    if error != nil {
                        print(error)
                        return
                    }
                    
                    let senderUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(senderUserId).child(receiverUserId)
                    
                    let messageId = messagechildIdRef.key
                    senderUserMessagesRef.updateChildValues([messageId: 1])
                    
                    let receiverUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(receiverUserId).child(senderUserId)
                    receiverUserMessagesRef.updateChildValues([messageId: 1])
                    
                    self.inputMessageTextField.text = ""
                    self.moveMessageInputTextfieldToOriginalPosition()
                }
    }
    
    //MARK:- Attachment Button Pressed
    @IBAction func attachmentBtnPressed(sender: AnyObject) {
    }
    
    
    //MARK:- Textview Delegate method
    func textViewDidChange(textView: UITextView) {
        let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat (MAXFLOAT)))
        inputTextHeightConstriant.constant = sizeThatFitsTextView.height
        chatViewHeightConstraint.constant =  inputTextHeightConstriant.constant + 10
    }
    
    
    //MARK:- Load messages
    //Fetch and load message conversation b/w current user and selected user
    func loadMessageConversation(){
        guard let currentUserId = FIRAuth.auth()?.currentUser?.uid,receiverId = user?.id else{
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(currentUserId).child(receiverId)
        userMessagesRef.observeEventType(.ChildAdded, withBlock:
        { (messageResult) in
            
            let messageId = messageResult.key
            let messagesRef = FIRDatabase.database().reference().child(kMessages).child(messageId)
            messagesRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                let message = Messages()
                //potential of crashing if keys don't match
                message.setValuesForKeysWithDictionary(dictionary)
                print("Messages:",message.messageText)
                self.messages.append(message)
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.messagesCollectionView?.reloadData()
                        let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                        self.messagesCollectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
                    })
                
                
            }, withCancelBlock: nil)
        }, withCancelBlock:nil)
    }
    

}


extension QMessagesListController:UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout{
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! QMessageCell
        let messageData = messages[indexPath.item]
        if let image = user?.profileImageUrl{
            cell.profileImage.loadImageUsingCacheWithUrlString(image)
        }
        cell.messageChats = messageData
        return cell
    }
    
    //MARK:- CollectionViewCell height
    //In this method, we are setting the height of the cell, according to the message text length.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var cellHeight:CGFloat = 90 //default height specified in storyboard
        if let messageString = messages[indexPath.item].messageText
        {
            cellHeight = QHelper.sharedHelper.calculateCollectionCellHeightForText(messageString).height + 20
        }
        return CGSize(width: view.frame.width, height: cellHeight)
    }
    
}

extension QMessagesListController{
    
    func setUpInitialNavBar(){
        inputMessageTextField.textAlignment = .Left
        inputMessageTextField.placeholder = "Type a message"
        selectedUserName.text = user?.name
        selectedUserProfileImage.loadImageUsingCacheWithUrlString(user!.profileImageUrl!)
        
        messagesCollectionView.alwaysBounceVertical = true
        messagesCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 5, 0)//Giving space to bottom of collectionview
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    //Here we will remove the observer ,which we set for the keyboard
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //Showing keyboard and making the chatbox to move up, when user start interaciton with textfield
    func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        chatViewBottonConstraint?.constant = keyboardFrame!.height
        UIView.animateWithDuration(0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
    //Moving chatbox down to its original position, once user done with texting. 
    func handleKeyboardWillHide(notification: NSNotification) {
        chatViewBottonConstraint?.constant = 0
        UIView.animateWithDuration(0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
    func moveMessageInputTextfieldToOriginalPosition(){
        chatViewBottonConstraint?.constant = 0
        UIView.animateWithDuration(0.1) {
            self.inputTextHeightConstriant.constant = 35
            self.chatViewHeightConstraint.constant =  45
            self.inputMessageTextField.resignFirstResponder()
            self.view.layoutIfNeeded()
        }
    }
    
}
