//
//  DetectDevice.swift
//  GooDic
//
//  Created by paxcreation on 6/25/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import UIKit

final class DetectDevice {
    
    enum RotationDevice {
        case landscapeLeft, landscapeRight, portrait, portraitUpDown
    }
    
    static var share = DetectDevice()
    
    var currentDevice:  UIUserInterfaceIdiom {
        return  UIDevice.current.userInterfaceIdiom
    }
    
    func detectLandscape(size: CGSize) -> Bool {
        let isLandscape = (size.height < size.width) ? true : false
        return isLandscape
    }
    
    func detectOrentation() -> RotationDevice {
        switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            default:
                return .portrait
        }
    }
    
}
