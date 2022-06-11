//
//  AuthenticationUseCaseProtocol.swift
//  GooDic
//
//  Created by ttvu on 12/30/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import GooidSDK

protocol AuthenticationUseCaseProtocol {
    func hasLoggedin() -> Observable<Bool>
    func refreshSession() -> Observable<Void>
    func logout() -> Observable<Void>
}

extension AuthenticationUseCaseProtocol {
    func hasLoggedin() -> Observable<Bool> {
        return Observable.just(GooidSDK.sharedInstance.isLoggedIn)
    }
        
    func logout() -> Observable<Void> {
        AppManager.shared.updateSearchUserPaidAfterLogin(login: false)
        GATracking.sendUserPropertiesAfterLogout()
        return GooidSDK.sharedInstance.rx.logout()
    }
    
    func refreshSession() -> Observable<Void> {
        return GooidSDK.sharedInstance.rx
            .refresh()
            .filter({ $0 == .success })
            .mapToVoid()
    }
}
