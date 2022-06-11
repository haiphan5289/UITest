//
//  UIImage+Extension.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIImage {
    class func fromAsset(name: String) -> UIImage {
        guard let image = UIImage(named: name) else {
            assertionFailure("missing \(name) image")
            
            return UIImage()
        }
        
        return image
    }
    
    class func fromLabel(_ label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        label.layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    class func fromView(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        view.layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    class func createActionTitleImage(name: String) -> UIImage? {
        let label = UILabel()
        label.text = name
        label.font = UIFont.hiraginoSansW4(size: 16)
        label.textColor = Asset.trashFill.color
        let size = label.sizeThatFits(CGSize(width: CGFloat.infinity, height: label.font.pointSize))
        label.frame = CGRect(origin: .zero, size: size)
        
        if let cgImage = UIImage.fromLabel(label).cgImage {
            /// in iOS 12, the image will be filled with white under the influence of the rendering mode. So, to ignore it, I used `ImageWithoutRender`
            return ImageWithoutRender(cgImage: cgImage, scale: UIScreen.main.nativeScale, orientation: .up)
        } else {
            return nil
        }
    }
}

