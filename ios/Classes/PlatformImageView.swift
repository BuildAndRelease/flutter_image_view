//
//  PlatformTextView.swift
//  Runner
//
//  Created by Wiki on 2020/2/2.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import Flutter
import SDWebImage

class PlatformImageView: NSObject,FlutterPlatformView {
    let frame: CGRect;
    let viewId: Int64;
    var imagePath: String = ""
    var imageData: Data = Data()
    var placeholderPath: String = ""
    var placeholderData: Data = Data()
    var radius : CGFloat = 0

    init(_ frame: CGRect,viewID: Int64,args :Any?) {
        self.frame = frame
        self.viewId = viewID
        if let dict = args as? NSDictionary{
            self.imagePath = (dict.value(forKey: "imagePath") as? String) ?? ""
            self.imageData = (dict.value(forKey: "imageData") as? Data) ?? Data()
            self.placeholderPath = (dict.value(forKey: "placeHolderPath") as? String) ?? ""
            self.placeholderData = (dict.value(forKey: "placeHolderData") as? Data) ?? Data()
            self.radius = (dict.value(forKey: "radius") as? CGFloat) ?? 0
        }
    }
    
    func view() -> UIView {
        let imageView = SDAnimatedImageView(frame: frame)
        imageView.tag = Int(viewId)
        imageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        imageView.contentMode = .scaleToFill
        if imageData.count > 0 {
            imageView.maxBufferSize = 1
            imageView.image = UIImage(data: imageData)
        }else {
            guard let url = (imagePath.starts(with: "/") ? URL(fileURLWithPath: imagePath) : URL(string: imagePath)) else {
                return imageView
            }
            let placeHolderImage = placeholderData.count > 0 ? UIImage(data: placeholderData) : nil
            imageView.sd_setImage(with: url, placeholderImage: placeHolderImage, options: [.lowPriority, .allowInvalidSSLCertificates, .avoidDecodeImage, .scaleDownLargeImages], completed: nil)
        }
        imageView.layer.cornerRadius = radius
        imageView.layer.masksToBounds = true
        return imageView
    }
}
