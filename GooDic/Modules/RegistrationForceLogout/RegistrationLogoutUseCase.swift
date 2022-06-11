//
//  RegistrationLogoutUseCase.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import GooidSDK

protocol RegistrationLogoutUseCaseProtocol {
    var statusServer: PublishSubject<Void> { get set}
    var statusServerError: PublishSubject<GooServiceError> { get set }
    var erroNetwork: PublishSubject<Error> { get set }
    var activityIndicator: ActivityIndicator { get set }
    func login(vc: UIViewController) -> Observable<GooIDResult>
    func validateServer()
    func getBillingInfoStatus() -> Observable<BillingInfo>
}

struct RegistrationLogoutUseCase: RegistrationLogoutUseCaseProtocol, AuthenticationUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
    var erroNetwork: PublishSubject<Error> = PublishSubject.init()
    var statusServerError: PublishSubject<GooServiceError> = PublishSubject.init()
    var activityIndicator: ActivityIndicator = ActivityIndicator()
    var statusServer: PublishSubject<Void> = PublishSubject.init()
    private let disposeBag = DisposeBag()
    
    func validateServer() {
        cloudService.gateway.getAPIStatus()
            .trackActivity(activityIndicator)
            .subscribe(
                onNext: { () in
                    statusServer.onNext(())
                },
                onError: { error in
                    if let error = error as? GooServiceError {
                        statusServerError.onNext(error)
                    } else {
                        erroNetwork.onNext(error)
                    }
                })
            .disposed(by: disposeBag)
    }
    
    func login(vc: UIViewController) -> Observable<GooIDResult> {
        return GooidSDK.sharedInstance.rx.login()
    }
    
    func getBillingInfoStatus() -> Observable<BillingInfo> {
        if GooidSDK.sharedInstance.isLoggedIn == false {
            return Observable.just(BillingInfo(platform: "", billingStatus: .free))
        }
        return CurrentCloudService().cloudService.gateway
            .getBillingStatus()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .catchError({ (error) -> Observable<GooResponseBillingInfo> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenanceCannotUpdate(let data):
                        if let responseBillingInfo = data as? GooResponseBillingInfo {
                            return Observable.just(responseBillingInfo)
                        }
                    default:
                        break
                    }
                }
                
                return Observable.error(error)
            })
            .map({ responseBillingInfo -> BillingInfo in
                return BillingInfo(platform: responseBillingInfo.platform, billingStatus: responseBillingInfo.billingStatus)
            })
    }
}
