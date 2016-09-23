//
//  QMessagesListController.swift
//  QChat
//
//  Created by Kishan Ravindra on 14/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase

class QMessagesListController: UIViewController,UITextViewDelegate,chatImagePickerHelperDelegate{
    
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
    @IBOutlet weak var attachmentBgViewWidth: NSLayoutConstraint!
    
    var user: Users?
    var messages = [Messages]()
    var isAttachmentBtnTapped = false
    var chatImagePicker: QChatImageUploader?
    var imageStartingFrame:CGRect?
    var zoomBackgroundView:UIView?
    var chatImageZoomView: UIImageView?
    
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
         changeAttachmentBgViewConstantToZero()
    }
    
    
    //MARK:- attachment Different actions(camera,gallery,video,voice & location)
    
    @IBAction func attachmentOptionSelected(sender: UIButton) {
        
        switch sender.tag {
        case 10:
            print("camera")
            checkIfImagePickerPresent()
            if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
            {
                chatImagePicker = QChatImageUploader(lSelectedController: self, chatImageDelagate: self, andSelectedSource: .Camera,userId:user?.id)
            }else{
              print("camera not available")
            }
            
        case 20:
            print("gallery")
            checkIfImagePickerPresent()
            openPhotoLibrary()
            
        case 30:
            print("video")
            checkIfImagePickerPresent()
            openPhotoLibrary()
        case 40:
            print("voice")
            
        default:
            print("location")
        }
        changeAttachmentBgViewConstantToZero()
    }
    
    //Checking if imagepicker is present, if so, make it to nil
    func checkIfImagePickerPresent(){
        self.view.endEditing(true)
        if chatImagePicker != nil{
            chatImagePicker = nil
        }
    }
    
    //Opening photo library to select image and video
    func openPhotoLibrary(){
        if(UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)){
            chatImagePicker = QChatImageUploader(lSelectedController: self, chatImageDelagate: self, andSelectedSource: .PhotoLibrary,userId:user?.id)
        }
    }
    
    //MARK:- QChatImageUploader Delegate
    func uploadStatusMessage(status: String){
        print("chat image upload status:",status)
    }
    
    func changeAttachmentBgViewConstantToZero(){
    isAttachmentBtnTapped =  isAttachmentBtnTapped ? false : true
        UIView.animateWithDuration(0.5, delay: 0.1, options: .CurveEaseInOut, animations:
            {
                if self.isAttachmentBtnTapped{
                    self.attachmentBgViewWidth.constant = 320
                }else{
                    self.attachmentBgViewWidth.constant = 0
                }
                self.view.layoutIfNeeded()
            }, completion: nil)
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
                
                self.messages.append(Messages(dictionary: dictionary))
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

//MARK:- UICOllectionViewDelegate Method
extension QMessagesListController:UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout{
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! QMessageCell
        let messageData = messages[indexPath.item]
        //Getting access QMessageListVc in QMessageCell
        cell.messageListVc = self
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
        let chatMessage = messages[indexPath.item]
        if let messageString = chatMessage.messageText
        {
            cellHeight = QHelper.sharedHelper.calculateCollectionCellHeightForText(messageString).height + 20
        }
        else if  chatMessage.chatImageUrl != nil, let imageWidth = chatMessage.chatImageWidth?.floatValue, imageHeight = chatMessage.chatImageHeight?.floatValue
        {
            //For image width and height
            cellHeight = CGFloat(imageHeight / imageWidth * 200)
        }
        return CGSize(width: UIScreen.mainScreen().bounds.width, height: cellHeight)
    }
    
    //MARK:- zoom the imageview - called from QMessageCell
    //In this method we will zoom the imageview, to see image clearly.
    func startZoomingChatMessageImageView(imageToZoom:UIImageView){
        chatImageZoomView? = imageToZoom
        chatImageZoomView?.hidden = true
        
        imageStartingFrame = imageToZoom.superview?.convertRect(imageToZoom.frame, toView: nil) //this will give us a image postion and size
        print(imageStartingFrame)
        
        //creating another imageview and place it on top of original image, which is suppose to be zoomed.
        let zoomImageView = UIImageView(frame: imageStartingFrame!)
        zoomImageView.image = imageToZoom.image
        zoomImageView.userInteractionEnabled = true
        zoomImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomOutImageView)))
        
        if let viewWindow = UIApplication.sharedApplication().keyWindow{
            
            zoomBackgroundView = UIView(frame: viewWindow.frame)
            zoomBackgroundView?.backgroundColor = .blackColor()
            zoomBackgroundView?.alpha = 0
            viewWindow.addSubview(zoomBackgroundView!)
            viewWindow.addSubview(zoomImageView)
            
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: { 
                self.zoomBackgroundView?.alpha = 1
                //we know height and width of image to be zoomed and we know width of image after it zoomed. so we need to calculate only of height of zoomed image.
                let zoomImageHeight  = self.imageStartingFrame!.height / self.imageStartingFrame!.width * viewWindow.frame.width
                
                zoomImageView.frame = CGRect(x: 0, y:0, width: viewWindow.frame.width, height: zoomImageHeight)
                zoomImageView.center = viewWindow.center
                }, completion: nil)
        }
    }
    
    //MARK:- zooming out the imageview, back its original position
    func zoomOutImageView(tapGesture:UITapGestureRecognizer){
        if let zoomOutImage = tapGesture.view as? UIImageView
        {
            zoomOutImage.layer.cornerRadius =  12
            zoomOutImage.clipsToBounds = true
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveEaseOut, animations: {
                zoomOutImage.frame = self.imageStartingFrame!
                self.zoomBackgroundView?.alpha = 0
                
                }, completion: { (completed) in
                    zoomOutImage.removeFromSuperview()
                    self.chatImageZoomView?.hidden = false
            })
        }
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
    func handleKeyboardDidShow(notification: NSNotification) {
       
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        chatViewBottonConstraint?.constant = keyboardFrame!.height
        UIView.animateWithDuration(0.2, delay: 0.2, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
        
        UIView.animateWithDuration(0.5, delay: 0.1, options: .CurveEaseOut, animations: {
            if self.messages.count > 0 {
                let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                self.messagesCollectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
            }
            }, completion: nil)
    }
    
    //Moving chatbox down to its original position, once user done with texting. 
    func handleKeyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.1, delay: 0.1, options: .CurveEaseIn, animations: {
            self.chatViewBottonConstraint?.constant = 0
            self.view.layoutIfNeeded()
            }, completion: nil)
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
