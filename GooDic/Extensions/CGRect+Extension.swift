//
//  CGRect+Extension.swift
//  GooDic
//
//  Created by ttvu on 6/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import CoreGraphics

extension CGRect {
    var topLeft: CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    
    var topRight: CGPoint {
        return CGPoint(x: maxX, y: minY)
    }
    
    var bottomLeft: CGPoint {
        return CGPoint(x: minX, y: maxY)
    }
    
    var bottomRight: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    
    var centerLeft: CGPoint {
        return CGPoint(x: minX, y: midY)
    }
    
    var centerRight: CGPoint {
        return CGPoint(x: maxX, y: midY)
    }
    
    var centerTop: CGPoint {
        return CGPoint(x: midX, y: minY)
    }
    
    var centerBottom: CGPoint {
        return CGPoint(x: midX, y: maxY)
    }
    
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
