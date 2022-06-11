//
//  GetHeightSafeArea.swift
//  CameraMakeUp
//
//  Created by haiphan on 22/09/2021.
//

import Foundation
import UIKit

final class GetHeightSafeArea {
    
    enum SafeAreaType {
        case top, bottom, left, right
    }
    
    static var shared = GetHeightSafeArea()
    private init() {}
 
    func getHeight(type: SafeAreaType) -> CGFloat {
        guard let window = UIApplication.shared.windows.first else {
            return 0
        }
        switch type {
        case .bottom:
            return window.safeAreaInsets.bottom
        case .top:
            return window.safeAreaInsets.top
        case .left:
            return window.safeAreaInsets.left
        case .right:
            return window.safeAreaInsets.right
        }
    }
    
}
