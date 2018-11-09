//
//  UIImageView+Promise.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/20.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import SDWebImage
import PromiseKit


extension UIImageView {
    
    @discardableResult
    func jy_setImage(with url: String, placeholderImage: UIImage? = nil) -> Promise<UIImage> {
        return Promise { seal in
            let url = URL(string: url)
            sd_setImage(with: url, placeholderImage: placeholderImage, options: SDWebImageOptions.init(rawValue: 0), completed: { [weak self] (image, error, cacheType, url) in
                guard let image = image, error == nil else {
                    seal.reject(error!)
                    return
                }

                self?.image = image
                seal.fulfill(image)
            })
        }
    }
    
    @discardableResult
    func jy_cacheImage(with url: String) -> Promise<UIImage> {
        return Promise { seal in
            let url = URL(string: url)
            sd_setImage(with: url, placeholderImage: nil, options: .cacheMemoryOnly, completed: { (image, error, cacheType, url) in
                guard let image = image, error == nil else {
                    seal.reject(error!)
                    return
                }
                
                seal.fulfill(image)
            })
        }
    }
    
    static func jy_removeCache(for url: String) {
        SDImageCache.shared().removeImage(forKey: url)
    }
}
