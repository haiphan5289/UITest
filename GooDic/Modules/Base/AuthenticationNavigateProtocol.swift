//
//  AuthenticationNavigateProtocol.swift
//  GooDic
//
//  Created by ttvu on 12/30/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

protocol AuthenticationNavigateProtocol: CoordinateProtocol {
    func toForceLogout()
}

extension AuthenticationNavigateProtocol {
    func toForceLogout() {
        RegistrationLogoutCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
}
