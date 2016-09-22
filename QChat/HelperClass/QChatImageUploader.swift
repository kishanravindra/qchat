//
//  QChatImageUploader.swift
//  QChat
//
//  Created by Kishan Ravindra on 22/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
@objc protocol chatImagePickerHelperDelegate :NSObjectProtocol{
    func uploadStatusMessage(status: String)
}

class QChatImageUploader: NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    weak var delegate: chatImagePickerHelperDelegate?
    let imagePicker = UIImagePickerController()
    var selectedController: UIViewController!
    var chatImage: UIImage?
    var receiverId:String!

    init(lSelectedController: UIViewController!, chatImageDelagate Delegate:chatImagePickerHelperDelegate!, andSelectedSource sourceType: UIImagePickerControllerSourceType!,userId:String?)
    {
        super.init()
        
        // initalizing the controller..
        selectedController = lSelectedController
        receiverId = userId
        delegate = Delegate
        imagePicker.delegate = self
        
        // opening the photo galary or the camera
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        selectedController.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //MARK:- ImagePicker Delegate Methods....
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage
        {
            chatImage = editedImage
        } else if
            let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            chatImage = originalImage
        }
        if let image = chatImage{
            uploadSelectedChatImageToFirebase(image)
        }
        selectedController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        selectedController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:- Upload image to Firbase storage
    func uploadSelectedChatImageToFirebase(capturedOrSelectedChatImage:UIImage){
        let imageName = NSUUID().UUIDString
        let imageRef = FIRStorage.storage().reference().child(kUserImages).child(imageName)
        
        if let imageData = UIImageJPEGRepresentation(capturedOrSelectedChatImage, 0.2){
            imageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil{
                    print("chat image upload error")
                    self.delegate?.uploadStatusMessage("failed")
                    return
                }
                
                if let chatImageUrl = metadata?.downloadURL()?.absoluteString {
                    print(chatImageUrl)
                    self.saveImageUr(chatImageUrl,chatImage:capturedOrSelectedChatImage)
                    self.delegate?.uploadStatusMessage("Success")
                }
            })
        }
    }
    
    private func saveImageUr(imageUrl:String,chatImage:UIImage)
    {
        let messageRef = FIRDatabase.database().reference().child(kMessages)
        //Generating unique id for each message, which user sends.
        let messagechildIdRef = messageRef.childByAutoId()
        //We will the map the message to recipient user with his account id.
        let receiverUserId = receiverId
        //Sender id
        let senderUserId = FIRAuth.auth()!.currentUser!.uid
        let timestamp: NSNumber = Int(NSDate().timeIntervalSince1970)
        let values = ["receiverId": receiverUserId, "senderId": senderUserId, "timeStamp": timestamp,"chatImageUrl": imageUrl,"chatImageWidth": chatImage.size.width, "chatImageHeight":chatImage.size.height]
        
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
        }
    }
}
