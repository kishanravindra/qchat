//
//  QWelcomeProfileController.swift
//  QChat
//
//  Created by Kishan Ravindra on 04/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
class QWelcomeProfileController: UIViewController {
     //MARK:-IBOutlets
    @IBOutlet weak var logoAnimatedImageView: UIImageView!
    @IBOutlet weak var termsAndConditionClickBtn: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var skipBtn: UIButton!
    var isTermsAndConditionBtnSelected = false //This Bool to check,whether term and condition btn selected or not
    var isUserProfilePresent:Bool? //This Bool to check,whether user uploaded his/her profile pic.
    var imagePicker: QImagePicker?
    var userId:String? // To get userId from the QLoginVc.We are creating this reference

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        animateLogoImageView()
        print(userId)
    }
    
    override func viewDidLayoutSubviews() {
        termsAndConditionClickBtn.layer.cornerRadius = termsAndConditionClickBtn.frame.size.height/2;
    }
    
    //Button Actions
    //MARK:- Add profile Image
    @IBAction func addProfileImageBtnPressed(sender: AnyObject){
        self.view.endEditing(true)
        if imagePicker != nil{
            imagePicker = nil
        }
        
        let optionMenu = UIAlertController(title: nil, message:"Choose Your Option", preferredStyle: .Alert)
        var cameraAction = UIAlertAction();
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            cameraAction = UIAlertAction(title:"Camera", style: UIAlertActionStyle.Default)
            { (alert) -> Void in
                print("Take Photo")
                QHelper.sharedHelper.showActivityIndicator(self, inidicatorText:"Uploading...")
                self.imagePicker = QImagePicker(lSelectedController: self, andImagePickerHelperDelegate: self, andSelectedSource: .Camera,userId: self.userId)
            }
        }
        else
        {
            print("Camera not available")
        }
        
        let GalleryAction = UIAlertAction(title:"Photos/Camera Roll", style: .Default, handler:
            {
                (alert: UIAlertAction) -> Void in
                print("Gallery", terminator: "")
                QHelper.sharedHelper.showActivityIndicator(self, inidicatorText:"Uploading...")
                self.imagePicker = QImagePicker(lSelectedController: self, andImagePickerHelperDelegate: self, andSelectedSource: .PhotoLibrary,userId: self.userId)
        })
        let cancelAction = UIAlertAction(title:"Cancel", style: .Cancel, handler: nil)
        optionMenu.addAction(cameraAction)
        optionMenu.addAction(GalleryAction)
        optionMenu.addAction(cancelAction)
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    //MARK:- Terms and conditions Click Button Action
    @IBAction func termsAndConditionClickBtnPressed(sender: AnyObject){
        isTermsAndConditionBtnSelected = isTermsAndConditionBtnSelected ? false: true
        termsAndConditionClickBtn.backgroundColor = isTermsAndConditionBtnSelected ? UIColor.darkGrayColor() : UIColor.whiteColor()
        skipBtn.setTitle(isTermsAndConditionBtnSelected ? "Done" : "Skip", forState: .Normal)
    }
    
    //MARK:- Terms and conditions popup button action
    //on click of this button, we will show the terms and condition details related to this applications.
    @IBAction func termsAndConditionPopupBtnPressed(sender: AnyObject){
    }
    
    //MARK:-Skip Button action
    @IBAction func skipBtnPressed(sender: AnyObject) {
        guard isTermsAndConditionBtnSelected  else{
          QHelper.sharedHelper.commonAlertView("Hello Qwinixan!", alertMessage: "Make sure you accepted our terms & condition", controller: self)
            return
        }
        //We are saving the reference of user acceptance of terms and condition. Once user accept the terms and condition,
         //next time onwards we will check in *ViewWillApper() -> QLoginVc , whether user accepted the conditions, if he/she does accepted.We will directly redirect them to QHomeVc.
        QHelper.sharedHelper.userAcceptanceStatusOnTermsAndCondition(isTermsAndConditionBtnSelected)
       dismissViewControllerAnimated(true, completion:nil)
    }
}

extension QWelcomeProfileController: ImagePickerHelperDelegate{
    //MARK:- User selection Image delegate
    func userSelectedImage(selectedImage: UIImage) {
            QHelper.sharedHelper.hideActivityIndicator(self)
            isUserProfilePresent = true
            profileImageView.image = selectedImage
            profileImageView.contentMode = .ScaleAspectFill
            profileImageView.clipsToBounds = true
    }
}

extension QWelcomeProfileController{
    //In this method, we are going to change the imageview every 2sec to create an image animation.
    func animateLogoImageView(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let imagesListArray:NSArray = [UIImage(named:"logo_orange")!,UIImage(named:"logo_whit")!,UIImage(named:"logo_green")!,UIImage(named:"logo_purple")!]
            dispatch_async(dispatch_get_main_queue(), { 
                self.logoAnimatedImageView.animationImages = imagesListArray as? [UIImage]
                self.logoAnimatedImageView.animationDuration = 2
                self.logoAnimatedImageView.startAnimating()
            })
        }
    }
}
