//
//  QChatListController.swift
//  QChat
//
//  Created by Kishan Ravindra on 07/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
class QChatListController: UIViewController {
    //IBOutlets
    @IBOutlet weak var starterInfoLabel: UILabel!
    @IBOutlet weak var chatListTable: UITableView!
    
    var messagesList = [Messages]()
    var messagesOfIndividualUser = [String:Messages]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        checkIfUserIsLoggedIn()
    }
    
    //Checking whether user is logged Into app or not, if not. We will logout the user
    func checkIfUserIsLoggedIn(){
        if FIRAuth.auth()?.currentUser?.uid == nil {
            performSelector(#selector(logoutTheUserFromApp), withObject: nil, afterDelay: 0)
        }
    }
    
    //MARK:- Logout the User
    func logoutTheUserFromApp(){
        do {
            try  FIRAuth.auth()?.signOut()
        } catch let error as NSError{
            QHelper.sharedHelper.commonAlertView(error.localizedDescription, alertMessage: "", controller: self)
        }
        QHelper.sharedHelper.userAcceptanceStatusOnTermsAndCondition(false)
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    
    func updateMessageList(){
        messagesList.removeAll()
        messagesOfIndividualUser.removeAll()
        checkUserMessages()
    }
    
    
    //MARK:- Fetching User messages
    //In this method, we will fetch message related to current user.
    //We use a "usermesssage" DB reference, from there we fetch the id's of message
    //then we pass to id to fetchMessageRelatedToUserConversation method.Which in terms fetch's all the message related to user, with refernce od message id.
    func checkUserMessages()
    {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            QHelper.sharedHelper.hideActivityIndicator(self)
            return
        }
        let userMessageRef = FIRDatabase.database().reference().child(kUserMessages).child(uid)
        userMessageRef.observeEventType(.ChildAdded, withBlock: { (messageResult) in
            let messageId = messageResult.key
            let messagesReference = FIRDatabase.database().reference().child(kMessages).child(messageId)
            
            messagesReference.observeSingleEventOfType(.Value, withBlock: { (result) in
                
                if let messageChatDict = result.value as? [String: AnyObject]
                {
                    self.starterInfoLabel.hidden = true
                    let messages = Messages()
                    messages.setValuesForKeysWithDictionary(messageChatDict)
                    if let receiverUserId = messages.checkForFromId() {
                        self.messagesOfIndividualUser[receiverUserId] = messages
                        self.messagesList = Array(self.messagesOfIndividualUser.values)
                        self.messagesList.sortInPlace({ (message1, message2) -> Bool in
                            return message1.timeStamp?.intValue > message2.timeStamp?.intValue
                        })
                    }
                    //this will crash because of background thread, so lets call this on dispatch_async main thread
                    dispatch_async(dispatch_get_main_queue(), {
                        self.chatListTable.reloadData()
                    })
                }
            }, withCancelBlock: nil)
            
        }, withCancelBlock: nil)
    }
    
    //MARK:- moving from QChatListVc to QMessagesListVc
    func selectedUserForChat(user:Users){
        performSegueWithIdentifier("ShowChatRoom", sender: user)
    }
    
    //Button Actions
    //MARK:- Menu Button action
    @IBAction func menuBtnPressed(sender: AnyObject) {
        logoutTheUserFromApp()
    }
    
    //MARK:-Contact List Button action
    @IBAction func contactListBtnPressed(sender: AnyObject) {
        performSegueWithIdentifier("ShowContactList", sender: self)
    }
    
    //MARK:- Search Button action
    @IBAction func searchBtnPressed(sender: AnyObject) {
    }
    
    //MARK:- prepareForSegue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowContactList"{
            let contactListVc = segue.destinationViewController as! QContactListController
            contactListVc.chatListVc = self
        }
        
        //From contact to chat room -------// ||  //From chatlist to chat room-------//
        if segue.identifier == "ShowChatRoom" || segue.identifier == "MoveToChatRoom" {
            let messageListVc = segue.destinationViewController as! QMessagesListController
            messageListVc.user = sender as? Users
        }
    }
}

extension QChatListController:UITableViewDelegate,UITableViewDataSource{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = chatListTable.dequeueReusableCellWithIdentifier("Cell") as! QChatListCell
        let messageDetails = messagesList[indexPath.row]
        cell.messageList = messageDetails
        QHelper.sharedHelper.hideActivityIndicator(self)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedUser = messagesList[indexPath.row]
        guard let messgedUserId = selectedUser.checkForFromId() else {
            return
        }
        let userMessageRef = FIRDatabase.database().reference().child(kUser).child(messgedUserId)
        userMessageRef.observeSingleEventOfType(.Value, withBlock:
        { (result) in
            if let messagedUserDict = result.value as? [String: AnyObject]{
                let user = Users()
                user.id = messgedUserId
                user.setValuesForKeysWithDictionary(messagedUserDict)
                self.performSegueWithIdentifier("MoveToChatRoom", sender: user)
            }
            
        }, withCancelBlock: nil)
    }
}

