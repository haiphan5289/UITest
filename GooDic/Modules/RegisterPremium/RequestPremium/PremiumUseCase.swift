//
//  PremiumUseCase.swift
//  GooDic
//
//  Created by Hao Nguyen on 5/26/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit
import GooidSDK
import RxCocoa

protocol PremiumUseCaseProtocol: AuthenticationUseCaseProtocol {
    var product: BehaviorRelay<SKProduct?> { get set }
    var statusServer: PublishSubject<Void> { get set}
    var statusServerError: PublishSubject<GooServiceError> { get set }
    var erroNetwork: PublishSubject<Error> { get set }
    var activityIndicator: ActivityIndicator { get set }
    
    func requestProducts() -> Observable<[SKProduct]?>
    func buyProduct(product: SKProduct)
    func sendReceipt(productId: String) -> Observable<Void>
    func getBillingInfoStatus() -> Observable<BillingInfo>
    func login() -> Observable<GooIDResult>
    func loggined()
    func userPaid(platform: String)
    func restorePurchase()
    func validateServer()
    func getUIBillingTextValue() -> Observable<FileStoreBillingText?>
}

struct PremiumUseCase: PremiumUseCaseProtocol {
    @GooInject var cloudService: CloudService
    @GooInject var remoteConfigService: RemoteConfigService
    
    var product: BehaviorRelay<SKProduct?> = BehaviorRelay(value: nil)
    var erroNetwork: PublishSubject<Error> = PublishSubject.init()
    var statusServerError: PublishSubject<GooServiceError> = PublishSubject.init()
    var statusServer: PublishSubject<Void> = PublishSubject.init()
    var activityIndicator: ActivityIndicator = ActivityIndicator()
    private let disposeBag = DisposeBag()
    
    func requestProducts() -> Observable<[SKProduct]?> {
        return Observable.create { (observer) -> Disposable in
           
            PremiumProduct.store.requestProducts { success, products in
                observer.onNext(products)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func buyProduct(product: SKProduct) {
        PremiumProduct.store.buyProduct(product)
        self.product.accept(product)
    }
    
    func sendReceipt(productId: String) -> Observable<Void> {
        cloudService.gateway.sendReceiptInfo(productId: productId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { _ in false })
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
    
    func login() -> Observable<GooIDResult> {
        return GooidSDK.sharedInstance.rx.login(waitingAPIListDevice: nil)
    }
    
    func loggined() {
        AppSettings.firstLogin = false
    }
    
    func userPaid(platform: String) {
        AppManager.shared.billingInfo.accept(BillingInfo(platform: platform, billingStatus: .paid))
    }
    
    func restorePurchase() {
        PremiumProduct.store.restorePurchases()
    }
    
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
    
    func getUIBillingTextValue() -> Observable<FileStoreBillingText?> {
        return remoteConfigService.gateway.getUIBillingTextValue()
    }
}
