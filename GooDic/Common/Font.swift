//
//  Font.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// Font helper
extension UIFont {
    class var normalFont: UIFont {
        hiraginoSansW4(size: 14)
    }
    
    class var textFieldFont: UIFont {
        hiraginoSansW4(size: 17)
    }
    
    class var textViewFont: UIFont {
        hiraginoSansW4(size: 14)
    }
    
    class func hiraginoSansW3(size: CGFloat) -> UIFont {
        return UIFont(name: "HiraginoSans-W3", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func hiraginoSansW4(size: CGFloat) -> UIFont {
        return UIFont(name: "HiraginoSans-W4", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func hiraginoSansW6(size: CGFloat) -> UIFont {
        return UIFont(name: "HiraginoSans-W6", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func hiraginoMinchoW3(size: CGFloat) -> UIFont {
        return UIFont(name: "HiraMinProN-W3", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
