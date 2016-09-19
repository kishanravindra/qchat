//
//  QContactCell.swift
//  QChat
//
//  Created by Kishan Ravindra on 07/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import UIKit

class QContactCell: UITableViewCell {

    var contacList : Users?{
        didSet{
            userName.text = contacList?.name
            if let profileImageURL = contacList?.profileImageUrl{
                profileImage.loadImageUsingCacheWithUrlString(profileImageURL)
               backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    //IBOutlet
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    @IBOutlet weak var logoImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
