//
//  UIDeviceOrientation+Description.swift
//  GooDic
//
//  Created by ttvu on 12/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIDeviceOrientation {
    func description() -> String {
        switch self {
        case .unknown: return "unknown"
        case .faceDown: return "faceDown"
        case .faceUp: return "faceUp"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        @unknown default:
            fatalError()
        }
    }
}

extension UIInterfaceOrientation {
    func description() -> String {
        switch self {
        case .unknown: return "unknown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        @unknown default:
            fatalError()
        }
    }
}

extension UIInterfaceOrientationMask {
    func description() -> String {
        switch self {
        case .all: return "all"
        case .allButUpsideDown: return "allButUpsideDown"
        case .landscape: return "landscape"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        default: return "value \(rawValue)"
        }
    }
}
