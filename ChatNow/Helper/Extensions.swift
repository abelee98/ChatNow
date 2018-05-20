//
//  Extensions.swift
//  ChatNow
//
//  Created by Abraham Lee on 5/19/18.
//  Copyright © 2018 Abraham Lee. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    func loadImageUsingCacheWithString(urlString: String) {
        
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) {
            
            self.image = cachedImage as? UIImage
            
            return
        }
        
        let imageString = URL(string: urlString)!
        let url = URLRequest(url: imageString)
        URLSession.shared.dataTask(with: url,  completionHandler: { (data, repsonse, error) in
            if error != nil {
                print(error ?? "error")
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!) {
                    
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    
                    self.image = downloadedImage
                }
                
            })
            
        }).resume()
    }
}

