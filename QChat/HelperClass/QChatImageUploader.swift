//
//  QChatImageUploader.swift
//  QChat
//
//  Created by Kishan Ravindra on 22/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

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
        imagePicker.mediaTypes = [kUTTypeImage as String,kUTTypeMovie as String]
        selectedController.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //MARK:- ImagePicker Delegate Methods....
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL {
            print(videoUrl)
            uploadSelectedChatVideoToFirebase(videoUrl)
        }
        else{
            uploadSelectedChatImageToFirebase(info)
        }
        selectedController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        selectedController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:- -----------------------------Video upload --------------------------------------//
    //MARK:- Upload video to Firebase Storage
    private func uploadSelectedChatVideoToFirebase(videoUrl:NSURL){
        let videoName = NSUUID().UUIDString + ".mov"
        let uploadingStatus = FIRStorage.storage().reference().child(kUserVideos).child(videoName).putFile(videoUrl, metadata: nil) { (videoMetaData, error) in
            
            if error != nil{
                print("chat video upload error",error?.localizedDescription)
                return
            }
            
            if let videoStorageUrl = videoMetaData?.downloadURL()?.absoluteString{
                print(videoStorageUrl)
                if let videoImageThumbnail = self.generateThumbnailImageFromVideo(videoUrl)
                {
                    self.uploadChatImageAndVideoToFirebaseStoreage(videoImageThumbnail
                        , completion: { (imageUrl) in
                            let chatVideoProperties:[String:AnyObject] = ["chatImageUrl":imageUrl,"chatImageWidth": videoImageThumbnail.size.width, "chatImageHeight":videoImageThumbnail.size.height,"videoUrl":videoStorageUrl]
                            self.saveChatImageAndVideoToFirebaseDb(chatVideoProperties)
                    })
                }
            }
        }
        
        //Checking for upload progess
        uploadingStatus.observeStatus(.Progress) { (progressStartedStatus) in
            print(progressStartedStatus.progress?.completedUnitCount)
        }
        
        uploadingStatus.observeStatus(.Success) { (progressSuccessStatus) in
            print("uplaod completed")
        }
    }
    
    
    //MARK:- Generate thumbnail image for vide0
    func generateThumbnailImageFromVideo(videoUrl:NSURL) -> UIImage?{
        let videoAsset = AVAsset(URL: videoUrl)
        let imageGeneratorForVideo = AVAssetImageGenerator(asset: videoAsset)
        
        do {
            let thumbnailCGImage = try imageGeneratorForVideo.copyCGImageAtTime(CMTimeMake(1, 60), actualTime: nil)
            return UIImage(CGImage: thumbnailCGImage)
        } catch let err {
            print("failed to generate thumbnail:",err)
        }
        return nil
    }
    //-----------------------------Video Upload------------------------------------------------//
    
    //MARK:---------------------- Image Upload ---------------------------------------------------//
    
    //MARK:- Upload image to Firbase storage
    private func uploadSelectedChatImageToFirebase(info:[String:AnyObject])
    {
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage
        {
            chatImage = editedImage
        } else if
            let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            chatImage = originalImage
        }
        if let capturedOrSelectedimage = chatImage{
            uploadChatImageAndVideoToFirebaseStoreage(capturedOrSelectedimage, completion: { (imageUrl) in
                self.saveImageUr(imageUrl,chatImage:capturedOrSelectedimage)
                self.delegate?.uploadStatusMessage("Success")
            })
        }
    }
    
    //First we upload chatImage to Firebase stoarge ,on completion we will send back the imageUrl and save it on firebase DB//
    private func uploadChatImageAndVideoToFirebaseStoreage(capturedOrSelectedimage:UIImage,completion:(imageUrl:String)->())
    {
        let imageName = NSUUID().UUIDString
        let imageRef = FIRStorage.storage().reference().child(kUserImages).child(imageName)
        
        if let imageData = UIImageJPEGRepresentation(capturedOrSelectedimage, 0.2){
            imageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil{
                    print("chat image upload error")
                    self.delegate?.uploadStatusMessage("failed")
                    return
                }
                
                if let chatImageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl: chatImageUrl)
                }
            })
        }
    }
    
    
    private func saveImageUr(imageUrl:String,chatImage:UIImage)
    {
        let chatImageProperties:[String:AnyObject] = ["chatImageUrl": imageUrl,"chatImageWidth": chatImage.size.width, "chatImageHeight":chatImage.size.height]
        saveChatImageAndVideoToFirebaseDb(chatImageProperties)
    }
    
    //-------------------------- Image upload -----------------------------------------//
    
    
    
    //MARK:- save chat image and video to firebase DB
    func saveChatImageAndVideoToFirebaseDb(properties: [String: AnyObject])
    {
        let messageRef = FIRDatabase.database().reference().child(kMessages)
        //Generating unique id for each message, which user sends.
        let messagechildIdRef = messageRef.childByAutoId()
        //We will the map the message to recipient user with his account id.
        let receiverUserId = receiverId
        //Sender id
        let senderUserId = FIRAuth.auth()!.currentUser!.uid
        let timestamp: NSNumber = Int(NSDate().timeIntervalSince1970)
        var values:[String:AnyObject] = ["receiverId": receiverUserId, "senderId": senderUserId, "timeStamp": timestamp]
        properties.forEach({values[$0] = $1})

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
