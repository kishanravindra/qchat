//
//  QContactListController.swift
//  QChat
//
//  Created by Kishan Ravindra on 07/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit
import Firebase
class QContactListController: UIViewController {

    //IBOutlets
    @IBOutlet weak var contactTableView: UITableView!
    
    var chatListVc:QChatListController?
    var users = [Users]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fetchAllEmployeesData()
        QHelper.sharedHelper.showActivityIndicator(self, inidicatorText: "Contacts are on the way...")
    }
    
    //Buttons
    //MARK:- Back Button action
    @IBAction func backBtnPressed(sender: AnyObject) {
     dismissViewControllerAnimated(true, completion: nil)
    }
    
    func fetchAllEmployeesData() {
       
        FIRDatabase.database().reference().child(kUser).observeEventType(.ChildAdded, withBlock: { (results) in
            if let dictionary = results.value as? [String: AnyObject] {
                print(dictionary)
                let user = Users()
                 //This will give us a user account id,which we going to use in sending message and mapping the messages to paticulat user.
                 user.id = results.key
                //if you use this setter, your app will crash if your class properties don't exactly match up with the firebase dictionary keys
                user.setValuesForKeysWithDictionary(dictionary)
                self.users.append(user)
                print(self.users.count)
                //this will crash because of background thread, so lets use dispatch_async to fix
                dispatch_async(dispatch_get_main_queue(), {
                    self.contactTableView.reloadData()
                })
            }
        }, withCancelBlock: nil)
    }
}

extension QContactListController:UITableViewDataSource,UITableViewDelegate{
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = contactTableView.dequeueReusableCellWithIdentifier("Cell") as! QContactCell
        let userDetails = users[indexPath.row]
        cell.contacList = userDetails
        QHelper.sharedHelper.hideActivityIndicator(self)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedUser = self.users[indexPath.row]
        self.chatListVc?.selectedUserForChat(selectedUser)
        dismissViewControllerAnimated(true, completion: nil)
    }
}
