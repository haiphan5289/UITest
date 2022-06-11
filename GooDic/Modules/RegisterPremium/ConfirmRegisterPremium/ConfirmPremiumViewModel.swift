//
//  ConfirmPremiumViewModel.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/2/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import StoreKit

struct ConfirmPremiumViewModel {
    let navigator: ConfirmPremiumNavigateProtocol
    let useCase: PremiumUseCaseProtocol
    
    init(navigator: ConfirmPremiumNavigateProtocol, useCase: PremiumUseCaseProtocol) {
        self.navigator = navigator
        self.useCase = useCase
    }
}

extension ConfirmPremiumViewModel: ViewModelProtocol {
    struct Input {
        let loadData: Driver<Void>
        let nextTrigger: Driver<Void>
        let dismissTrigger: Driver<Void>
        let purcharseSucceed: Driver<Void>
        let useInfo: Driver<UserInfo?>
        let privacyTrigger: Driver<Void>
        let termTrigger: Driver<Void>
    }
    
    struct Output {
        let buyProductTrigger: Driver<Void>
        let dismissTrigger: Driver<Void>
        let listProducts: Driver<[SKProduct]?>
        let purcharseSucceed: Driver<Void>
        let titleNextButton: Driver<String>
        let viewPrivacyAction: Driver<Void>
        let viewTermAction: Driver<Void>
        let loading: Driver<Bool>
        let result: Driver<Void>
        let userPaidAction: Driver<Void>
        let errorBillingHandler: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let userPaidTrigger = PublishSubject<BillingInfo>.init()

        let userPaidAction = userPaidTrigger.asObserver()
            .do(onNext: { (result) in
                self.useCase.userPaid(platform: result.platform)
                self.navigator.toDismiss()
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let products = input.loadData
            .asObservable()
            .flatMap { self.useCase.requestProducts().asDriverOnErrorJustComplete() }
            .flatMap({ (list) -> Observable<[SKProduct]?> in
                return Observable.just(list)
            })
            .asDriverOnErrorJustComplete()
        
        let sttServer = self.useCase.statusServer.observeOn(MainScheduler.asyncInstance)
        let errServer = self.useCase.statusServerError
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (err) -> Driver<Void> in
                switch err {
                case .maintenance:
                    return self.navigator
                        .showMessage(L10n.ErrorDevice.Error.maintenance)
                        .asDriverOnErrorJustComplete()
                case .maintenanceCannotUpdate(_):
                    return self.navigator
                        .showMessage(L10n.ListDevivice.Server.Error.cannotBeUpdate)
                        .asDriverOnErrorJustComplete()
                case .otherError(let errorCode):
                    return self.navigator
                        .showMessage(errorCode: errorCode)
                        .asDriverOnErrorJustComplete()
                default:
                    return Driver.empty()
                }
            })
        let errorNetwork = self.useCase.erroNetwork
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (err) -> Driver<Void> in
                return self.navigator
                    .showMessage(L10n.Login.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })

        let tapToMain = input.nextTrigger
            .do { _ in
                self.useCase.validateServer()
            }
        
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTracker = ErrorTracker()
        let errorBillingHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                                
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                    case .receiptInvalid:
                        return self.navigator
                            .showMessage(error.description)
                            .asDriverOnErrorJustComplete()
                        
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
            
        let checkBillingStatus = self.useCase.getBillingInfoStatus()
            .trackError(errorTracker)
        
        let result = Observable.merge(sttServer, errServer, errorNetwork)
            .flatMapLatest { checkBillingStatus }
            .withLatestFrom(products, resultSelector: { (data: $0, products: $1) })
            .withLatestFrom(input.useInfo, resultSelector: { (productData: $0, userInfo: $1) })
            .do(onNext: { (obj) in
                AppManager.shared.updateSettingSearch(billingStatus: obj.productData.data)
                if obj.productData.data.billingStatus == .paid {
                    userPaidTrigger.onNext(obj.productData.data)
                } else if let product = obj.productData.products?.first {
                    self.useCase.buyProduct(product: product)
                }
            }).asDriverOnErrorJustComplete().mapToVoid()
        
        let dismissTrigger = input.dismissTrigger
            .do { _ in
                self.navigator.toDismiss()
            }
        
        let activityIndicator = self.useCase.activityIndicator
        let error = ErrorTracker()
        let errorHandler = error
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode)
                            .asDriverOnErrorJustComplete()
                    case .errorHttpStatus(let statuscode):
                        var message = L10n.Server.Error.timeOut
                        if statuscode == "400" { message = L10n.Premium.Receipt.Err._400.message }
                        if statuscode == "409" { message = L10n.Premium.Receipt.Err._409.message }
                        if statuscode == "410" { message = L10n.Premium.Receipt.Err._410.message }
                        if statuscode == "500" {
                            return self.navigator
                                .showMessage(errorCode: statuscode)
                                .asDriverOnErrorJustComplete()
                        }
                        
                        if statuscode == "401" {
                            return self.useCase.logout()
                                .observeOn(MainScheduler.instance)
                                .do(onNext: self.navigator.toForceLogout).asDriverOnErrorJustComplete()
                        }
                        
                        return self.navigator
                            .showMessage(message)
                            .asDriverOnErrorJustComplete()
                    case .receiptEmpty:
                        return self.navigator
                            .showMessage(L10n.userHaveNotEverBeenPurchase)
                            .asDriverOnErrorJustComplete()
                    default:
                        return Driver.empty()
                    }
                }
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
            .flatMap({ _ -> Driver<Void> in
                Driver.empty()
            })
        
        let purcharseSucceed = input.purcharseSucceed
            .flatMap({
                self.useCase.sendReceipt(productId: self.useCase.product.value?.productIdentifier ?? "")
                    .trackActivity(activityIndicator)
                    .trackError(error).asDriverOnErrorJustComplete()
            })
            .flatMap { checkBillingStatus.asDriverOnErrorJustComplete() }
            .do(onNext: { (obj) in
                self.useCase.userPaid(platform: obj.platform)
                AppManager.shared.updateSettingSearch(billingStatus: obj)
            })
            .flatMap({ (error) -> Driver<Void> in
                return self.navigator
                    .showMessage(L10n.Premium.Message.success).asDriverOnErrorJustComplete()
            })
            .do(onNext: { _ in
                self.navigator.toDismiss()
            })
            .mapToVoid()
        
        let purcharseFlow = Driver.merge(purcharseSucceed, errorHandler)
            
        let titleNextButton = input.useInfo.asObservable()
            .flatMap({ (userinfo) -> Observable<String> in
                guard let _ = userinfo else {
                    return Observable.just(L10n.Premium.login)
                }
                return Observable.just(L10n.Premium.register)
            })
            .asDriverOnErrorJustComplete()
        
        let viewTermAction = input.termTrigger
            .do(onNext: { (obj) in
                if let url = URL(string: GlobalConstant.termURL) {
                    self.navigator.toWebView(url: url, cachePolicy: .reloadIgnoringCacheData, title: L10n.Menu.Cell.terms, sceneType: GATracking.Scene.terms, internalLinkDatas: [LinkData(title: L10n.Menu.Cell.appPrivacyPolicy,
                                                                                                                                                                                           sceneType: GATracking.Scene.appPolicy,
                                                                                                                                                                                           cachePolicy: .reloadIgnoringCacheData,
                                                                                                                                                                                           ulr: GlobalConstant.appPolicyURL),
                                                                                                                                                                                  LinkData(title: L10n.Menu.Cell.commercialTransactions,
                                                                                                                                                                                           sceneType: GATracking.Scene.law,
                                                                                                                                                                                            cachePolicy: .reloadIgnoringCacheData,
                                                                                                                                                                                            ulr: GlobalConstant.commercialTransactions)])
                }
            }).mapToVoid()
        
        let viewPrivacyAction = input.privacyTrigger
            .do(onNext: { (obj) in
                if let url = URL(string: GlobalConstant.appPolicyURL) {
                    self.navigator.toWebView(url: url, cachePolicy: .reloadIgnoringCacheData, title: L10n.Menu.Cell.privacyPolicy, sceneType: GATracking.Scene.appPolicy, internalLinkDatas: nil)
                }
            }).mapToVoid()
        
        return Output(
            buyProductTrigger: tapToMain,
            dismissTrigger: dismissTrigger,
            listProducts: products,
            purcharseSucceed: purcharseFlow,
            titleNextButton: titleNextButton,
            viewPrivacyAction: viewPrivacyAction,
            viewTermAction: viewTermAction,
            loading: activityIndicator.asDriver(),
            result: result,
            userPaidAction: userPaidAction,
            errorBillingHandler: errorBillingHandler
        )
    }
}
