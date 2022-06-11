//
//  ReusableView.swift
//  GooDic
//
//  Created by ttvu on 5/27/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

// Object, that adopts this protocol, will use identifier that matches name of its class
protocol ReusableView: class {
    
}

extension ReusableView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
