//
//  AuthenticationGooIDGateway.swift
//  GooDic
//
//  Created by ttvu on 11/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import GooidSDK
import RxSwift

public struct AuthenticationGooIDGateway: AuthenticationGatewayProtocol {
    public func login(_ viewController: UIViewController) -> Observable<AuthenResult> {
        return Observable.create { (observer) -> Disposable in
           
            GooidSDK.sharedInstance.login(viewController) { (ticket, error) in
                if ticket != nil {
                    observer.onNext(.success)
                } else {
                    let err = GooidSDKError(error)
                    
                    if err.isCancel {
                        observer.onNext(.cancel)
                    } else {
                        observer.onNext(.failure(error!))
                        observer.onError(error!)
                    }
                }
                
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
        
    }
}
