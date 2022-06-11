//
//  UIView+Nib.swift
//  GooDic
//
//  Created by ttvu on 5/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIView {
    class func fromNib<T: UIView>() -> T {
        let nibName = String(describing: T.self)// T.className
        return Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)![0] as! T
    }
    
    func fromNib() -> UIView {
        let nibName = String(describing: type(of: self))// self.className
        let bundle = Bundle(for: type(of: self))
        let nib = bundle.loadNibNamed(nibName, owner: self, options: nil)
        return nib![0] as! UIView
    }
    static var identifider: String {
        return "\(self)"
    }
    static var nib: UINib? {
        let bundle = Bundle(for: self)
        let name = "\(self)"
        guard bundle.path(forResource: name, ofType: "nib") != nil else {
            fatalError("don't have data")
        }
        return UINib(nibName: name, bundle: nil)
    }
}
protocol LoadXibProtocol {}
extension LoadXibProtocol where Self: UIView {
    static func loadXib() -> Self {
        let bundle = Bundle(for: self)
        let name = "\(self)"
        guard let view = UINib(nibName: name, bundle: bundle).instantiate(withOwner: nil, options: nil).first as? Self else {
            fatalError("error xib \(name)")
        }
        return view
    }
}
extension UIView: LoadXibProtocol {}
