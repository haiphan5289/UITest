//
//  AppManagerProtocol.swift
//  GooDic
//
//  Created by Vinh Nguyen on 17/01/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

protocol AppManagerProtocol: CoordinateProtocol {
    func moveToRegisterPremium()
}

extension AppManagerProtocol {
    func moveToRegisterPremium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
    }
}
