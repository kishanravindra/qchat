//
//  QLoginController.swift
//  QChat
//
//  Created by Kishan Ravindra on 02/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import MessageUI
import Firebase
class QLoginController:VideoSplashViewController,UITextFieldDelegate,MFMailComposeViewControllerDelegate {

    //MARK:-IBOutlets
    @IBOutlet weak var employeeTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var QChatListVc:QChatListController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupVideoBackground()
        setUpInitialUserInterface()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //Checking whether user accepted terms and condition. If he/she already accepte,then move to QHomeVc ,else Login
        print(FIRAuth.auth()?.currentUser?.uid)
        moveToChatListVc()
    }
    
    //MARK:-TextField Delegate Method
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK:-Login Button Action
    @IBAction func loginBtnPressed(sender: AnyObject){
        passwordTextField.resignFirstResponder()
        //Checking whether both employee and password field is filled.If not throw an error, else send a request to firebase
        if !employeeTextField.text!.isEmpty && !passwordTextField.text!.isEmpty{
            
            guard let employeeEmail = employeeTextField.text,password = passwordTextField.text else {
                return
            }
            QHelper.sharedHelper.showActivityIndicator(self, inidicatorText: "Logging In...")
            FIRAuth.auth()?.signInWithEmail(employeeEmail, password: password, completion: { (user, error) in
                
                    print(user?.uid)
                   //If error is not nil, throw an error
                    if error != nil{
                        QHelper.sharedHelper.hideActivityIndicator(self)
                        QHelper.sharedHelper.commonAlertView(error!.localizedDescription, alertMessage: "", controller: self)
                    }
                    QHelper.sharedHelper.hideActivityIndicator(self)
                    self.performSegueWithIdentifier("ShowWelcomePage", sender: user?.uid)
                })
        }else{
            QHelper.sharedHelper.commonAlertView("Warning!", alertMessage: "All fields are mandatory", controller: self)
        }
    }
        
    
    
    //MARK:-Contact Administrator Button Action
    @IBAction func contactAdministratorBtnPressed(sender: AnyObject){
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposerVC.setToRecipients(["rkishan@qwinix.io"])
        mailComposerVC.setSubject("qchat login credentials request")
        mailComposerVC.setMessageBody("I need credentails", isHTML: false)
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposerVC, animated: true, completion: nil)
        } else {
            QHelper.sharedHelper.commonAlertView("Could Not Send Email", alertMessage: "Your device could not send e-mail.  Please check e-mail configuration and try again.", controller: self)
        }
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:- Perpare for segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowWelcomePage"{
            let welcomeVc = segue.destinationViewController as? QWelcomeProfileController
            welcomeVc!.userId = sender as? String
        }
        
        if segue.identifier == "ShowHomePage"{
            let chatVc = segue.destinationViewController as? QChatListController
            chatVc?.updateMessageList()
        }
    }
}

extension QLoginController{
    //This method is respopnsible for displaying the splash video, when the app first lanuchs
    func setupVideoBackground()
    {
        let url = NSURL.fileURLWithPath((NSBundle.mainBundle().pathForResource("LaunchVideo", ofType:"mp4"))!)
        videoFrame = view.frame
        fillMode = .ResizeAspectFill
        alwaysRepeat = true
        sound = true
        startTime = 12.0
        alpha = 0.8
        contentURL = url
    }
    
    
    //Setting the intial UI for the view
    func setUpInitialUserInterface(){
         //Changing the placeholder color of textfield
        let placeHolderColor = UIColor.whiteColor()
        employeeTextField.attributedPlaceholder  = NSAttributedString(string:"Employee Email", attributes:[NSForegroundColorAttributeName:placeHolderColor])
        passwordTextField.attributedPlaceholder  = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName:placeHolderColor])
    }
    
    func moveToChatListVc(){
        employeeTextField.text = ""
        passwordTextField.text = ""
        print(QHelper.sharedHelper.userTermsAndConditionStatus())
        let logginStatus:Bool? = QHelper.sharedHelper.userTermsAndConditionStatus()
        if logginStatus == true {
            print("move")
            performSegueWithIdentifier("ShowHomePage", sender: self)
        }else{
            print("can't login")
        }
    }
    
    //Setting the toolbar for the employee textfield, whose type of keyboard is Number keyboard
    func setUpToolBarForEmployeeIdTextField(){
        //Setting Toolbar for textView
        let toolBar = UIToolbar(frame: CGRectMake(0, view.bounds.size.height, 320, 44))
        toolBar.barStyle = UIBarStyle.Black
        toolBar.translucent = true
        
        //Creating a flexible space for button
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: self, action: nil)
        
        //creating anf Adding custom button and adding image to toolbar
        let toolBarBtnImage  = UIImage(named:"right.png")
        let toolBarBtn = UIButton(type:UIButtonType.Custom)
        toolBarBtn.bounds = CGRectMake(0,0,(toolBarBtnImage?.size.width)!,(toolBarBtnImage?.size.height)!)
        toolBarBtn .setImage(toolBarBtnImage, forState: UIControlState.Normal)
        toolBarBtn .addTarget(self, action: #selector(QLoginController.doneWithUIPicker), forControlEvents: UIControlEvents.TouchUpInside)
        
        //Adding custom button to bar button
        let doneBtn = UIBarButtonItem(customView: toolBarBtn)
        
        //Creating an array of BarButtonItem and adding the barbuttomitem
        var btnItems = [UIBarButtonItem]()
        btnItems.append(flexible)
        btnItems.append(doneBtn)
        toolBar.items = btnItems
        toolBar.sizeToFit()
        
        employeeTextField.delegate = self
        employeeTextField.userInteractionEnabled = true
        employeeTextField.inputAccessoryView = toolBar
    }
    
    func doneWithUIPicker()
    {
        employeeTextField.resignFirstResponder()
        passwordTextField.becomeFirstResponder()
    }
}
