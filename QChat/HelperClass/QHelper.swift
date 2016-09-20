//
//  QHelper.swift
//  QChat
//
//  Created by Kishan Ravindra on 03/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
class QHelper: NSObject {
     static let sharedHelper = QHelper()
    
    //MARK:-Common AlertView Controller
    func commonAlertView(alertTitle: NSString, alertMessage: NSString,controller:UIViewController)
    {
        let alertController = UIAlertController(title: alertTitle as String, message: alertMessage as String, preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okButton)
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    //MARK:- save terms and condition saved status
    func userAcceptanceStatusOnTermsAndCondition(isAccepted:Bool){
        let statusTC = NSUserDefaults.standardUserDefaults()
        statusTC.setBool(isAccepted, forKey: kTermsAndConditionStatus)
        statusTC.synchronize()
    }
    
    //MARK:- Fetch user terms and condition status
    func userTermsAndConditionStatus()->Bool?
    {
        let status = NSUserDefaults.standardUserDefaults().valueForKey(kTermsAndConditionStatus)
        return status as? Bool
    }
    
    
    func formatDate(messageDate:Double)-> String{
        let timeAndDate = NSDate(timeIntervalSince1970: messageDate)
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "dd MMM hh:mm a"
        return dateFormat.stringFromDate(timeAndDate)
    }
    
    func calculateCollectionCellHeightForText(text: String) -> CGRect {
        //width is 200,which we specified in autolayout and we will give random height
        let size = CGSize(width: 200, height: 1000)
        return NSString(string: text).boundingRectWithSize(size, options: NSStringDrawingOptions.UsesFontLeading.union(.UsesLineFragmentOrigin), attributes: [NSFontAttributeName: UIFont.systemFontOfSize(15)], context: nil)
    }
    
    //MARK:-Method to display the activity Indicator
    func showActivityIndicator(controller:UIViewController,inidicatorText:String)
    {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(controller.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.color = UIColor(red: 0.89, green: 0.43, blue: 0.29, alpha: 1)
        loadingNotification.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        loadingNotification.labelText = inidicatorText
        loadingNotification.labelFont = UIFont(name:"TitilliumWeb-SemiBold", size: 16)
    }
    
    //MARK:-Method to Hide the activity Indicator
    func hideActivityIndicator(controller:UIViewController)
    {
        MBProgressHUD.hideAllHUDsForView(controller.view, animated: true)
    }
}
