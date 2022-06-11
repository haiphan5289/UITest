//
//  ConfirmPremiumUseCase.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/2/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit
import RxCocoa

protocol ConfirmPremiumUseCaseProtocol {
    var product: BehaviorRelay<SKProduct?> { get set }
    
    func requestProducts() -> Observable<[SKProduct]?>
    func buyProduct(product: SKProduct)
    func sendReceipt(productId: String) -> Observable<Void>
    func userPaid(platform: String)
    func getBillingInfoStatus() -> Observable<BillingInfo>
}

struct ConfirmPremiumUseCase: ConfirmPremiumUseCaseProtocol {
    @GooInject var cloudService: CloudService
    
    var product: BehaviorRelay<SKProduct?> = BehaviorRelay(value: nil)
    
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
        self.product.accept(product)
        PremiumProduct.store.buyProduct(product)
    }
    
    func sendReceipt(productId: String) -> Observable<Void> {
        cloudService.gateway.sendReceiptInfo(productId: productId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func getBillingInfoStatus() -> Observable<BillingInfo> {
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
    
    func userPaid(platform: String) {
        AppManager.shared.billingInfo.accept(BillingInfo(platform: platform, billingStatus: .paid))
    }
}
