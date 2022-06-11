//
//  AuthenticationService.swift
//  GooDic
//
//  Created by ttvu on 11/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public enum AuthenResult {
    case success
    case failure(Error)
    case cancel
}

public protocol AuthenticationGatewayProtocol {
    func login(_ viewController: UIViewController) -> Observable<AuthenResult>
}

public typealias AuthenticationService = GooService<AuthenticationGatewayProtocol>
