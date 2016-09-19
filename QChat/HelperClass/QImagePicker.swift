//
//  QImagePicker.swift
//  QChat
//
//  Created by Kishan Ravindra on 05/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
@objc protocol ImagePickerHelperDelegate :NSObjectProtocol{
    func userSelectedImage(selectedImage: UIImage)
}

class QImagePicker: NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    weak var delegate: ImagePickerHelperDelegate?
    
    let imagePicker = UIImagePickerController()
    var selectedController: UIViewController!
    var userFirebaseId:String!
    var selectedImage: UIImage?
    
    init(lSelectedController: UIViewController!, andImagePickerHelperDelegate lDelegate: ImagePickerHelperDelegate!, andSelectedSource sourceType: UIImagePickerControllerSourceType!,userId:String!) {
        super.init()
        
        userFirebaseId = userId
        print(userFirebaseId)
        // initalizing the controller..
        selectedController = lSelectedController
        delegate = lDelegate
        imagePicker.delegate = self
        
        // opening the photo galary or the camera
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        selectedController.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //MARK:- ImagePicker Delegate Methods....
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage
        {
            selectedImage = editedImage
        } else if
        let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImage = originalImage
        }
        
        //Checking whether user already have an profile image
        
        
        //successfully authenticated user
        let userProfileImageName = NSUUID().UUIDString
        let imageStorageRef = FIRStorage.storage().reference().child("profile_images").child("\(userProfileImageName).jpg")
        
        if let uploadImage = self.selectedImage, uploadImageData = UIImageJPEGRepresentation(uploadImage, 0.1)
        {
            imageStorageRef.putData(uploadImageData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print(error)
                    return
                }
                print(metadata)
                if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                    let values = ["profileImageUrl": profileImageUrl]
                    self.registerUserProfileImageIntoDatabaseWithUID(self.userFirebaseId, values: values)
                }
            })
        }
        // dismissing the controller
        self.selectedController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        selectedController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //Registering the User profile image
    private func registerUserProfileImageIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        let referenceURL = FIRDatabase.database().referenceFromURL("\(BASE_URL)")
        let usersReference = referenceURL.child(kUser).child(uid)
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err)
                return
            }
        })
        self.delegate?.userSelectedImage(self.selectedImage!)
    }

}
