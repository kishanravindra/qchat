//
//  QImageDownloader.swift
//  QChat
//
//  Created by Kishan Ravindra on 07/09/16.
//  Copyright © 2016 Kishan Ravindra. All rights reserved.
//

import Foundation
import UIKit

let imageCache = NSCache()

extension UIImageView
{
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        //check whether cache already have a  image ,If it has image , return that image
        if let cachedImage = imageCache.objectForKey(urlString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //otherwise Start downloading
        let url = NSURL(string: urlString)
        NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error)
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString)
                    self.image = downloadedImage
                }
            })
        }).resume()
    }
}