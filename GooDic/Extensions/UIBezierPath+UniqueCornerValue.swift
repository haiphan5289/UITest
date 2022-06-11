//
//  UIBezierPath+UniqueCornerValue.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIBezierPath {
    convenience init(roundRect rect: CGRect, topLeftRadius: CGSize = .zero, topRightRadius: CGSize = .zero, bottomLeftRadius: CGSize = .zero, bottomRightRadius: CGSize = .zero) {
        self.init()
        
        let path = CGMutablePath()
        
        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        if topLeftRadius != .zero {
            path.move(to: CGPoint(x: topLeft.x + topLeftRadius.width, y: topLeft.y))
        } else {
            path.move(to: topLeft)
        }
        
        if topRightRadius != .zero {
            let beginPoint = CGPoint(x: topRight.x - topRightRadius.width, y: topRight.y)
            let endPoint = CGPoint(x: topRight.x, y: topRight.y + topRightRadius.height)
            path.addLine(to: beginPoint)
            path.addCurve(to: endPoint, control1: topRight, control2: endPoint)
        } else {
            path.addLine(to: topRight)
        }
        
        if bottomRightRadius != .zero {
            let beginPoint = CGPoint(x: bottomRight.x, y: bottomRight.y - bottomRightRadius.height)
            let endPoint = CGPoint(x: bottomRight.x - bottomRightRadius.width, y: bottomRight.y)
            path.addLine(to: beginPoint)
            path.addCurve(to: endPoint, control1: bottomRight, control2: endPoint)
        } else {
            path.addLine(to: bottomRight)
        }
        
        if bottomLeftRadius != .zero {
            let beginPoint = CGPoint(x: bottomLeft.x + bottomLeftRadius.width, y: bottomLeft.y)
            let endPoint = CGPoint(x: bottomLeft.x, y: bottomLeft.y - bottomLeftRadius.height)
            path.addLine(to: beginPoint)
            path.addCurve(to: endPoint, control1: bottomLeft, control2: endPoint)
        } else {
            path.addLine(to: bottomLeft)
        }
        
        if topLeftRadius != .zero {
            let beginPoint = CGPoint(x: topLeft.x, y: topLeft.y + topLeftRadius.height)
            let endPoint = CGPoint(x: topLeft.x + topLeftRadius.width, y: topLeft.y)
            path.addLine(to: beginPoint)
            path.addCurve(to: endPoint, control1: topLeft, control2: endPoint)
        } else {
            path.addLine(to: topLeft)
        }
        
        path.closeSubpath()
        cgPath = path
    }
}

