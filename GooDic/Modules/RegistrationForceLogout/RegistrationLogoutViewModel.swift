//
//  RegistrationLogoutViewModel.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//
import Foundation
import RxSwift
import RxCocoa

struct RegistrationLogoutViewModel {
    var navigator: RegistrationLogoutNavigateProtocol
    var useCase: RegistrationLogoutUseCase
}

extension RegistrationLogoutViewModel: ViewModelProtocol {
    struct Input {
        let tapAction: Driver<TypeGooIDSKD>
    }
    
    struct Output {
        let tapToMain: Driver<TypeGooIDSKD>
//        let status: Driver<Void>
//        let err: Driver<Void>
//        let errNetwork: Driver<Void>
        let loading: Driver<Bool>
        let result: Driver<Void>
        let checkBillingStatusAction: Driver<Void>
        let errorBillingHandler: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let checkBillingStatus = PublishSubject<Void>.init()
        
        let tapToMain = input.tapAction
            .do { type in
                switch type {
                case .ignore:
                    self.navigator.toGooLoginView()
                default:
                    self.useCase.validateServer()
                }
            }
        
        let sttServer = self.useCase.statusServer.observeOn(MainScheduler.asyncInstance)
        let errServer = self.useCase.statusServerError
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (err) -> Observable<Void> in
                switch err {
                case .maintenance:
                    return self.navigator.showMessage(L10n.ErrorDevice.Error.maintenance)
                case .maintenanceCannotUpdate(_):
                    return self.navigator.showMessage(L10n.ListDevivice.Server.Error.cannotBeUpdate)
                case .otherError(let errorCode):
                    return self.navigator.showMessage(errorCode: errorCode)
                default:
                    return Observable.empty()
                }
            })
        let errorNetwork = self.useCase.erroNetwork
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (err) -> Observable<Void> in
                return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)

            })
        
        let result = Observable.merge(sttServer, errServer, errorNetwork)
            .withLatestFrom(input.tapAction.asObservable(), resultSelector: { (d, type) -> Driver<GooIDResult> in
            switch type {
            case .login:
                return  self.useCase.login(vc: navigator.viewcontroller).asDriverOnErrorJustComplete()
            default:
                return Driver.just(GooIDResult.cancel)
            }
        })
        .flatMap { $0 }
        .do { r in
            switch r {
            case .success:
                checkBillingStatus.onNext(())
            default:
                break
            }
        }
        .mapToVoid()
        .asDriverOnErrorJustComplete()
        
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTrackerBillingStatus = ErrorTracker()
        let errorBillingHandler = errorTrackerBillingStatus
            .asObservable()
            .flatMap({ (error) -> Observable<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                                
                    case .authenticationError:
                        return Observable.empty()
                    case .otherError(let errorCode):
                        return self.navigator.showMessage(from: self.navigator.viewcontroller,
                                                          errorCode: errorCode,
                                                          message: L10n.Server.Error.Other.message,
                                                          hyperlink: L10n.Server.Error.Other.hyperlink,
                                                          link: GlobalConstant.errorInfoURL)
                    default:
                        return Observable.just(())
                    }
                }
                return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let retryBillingAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let checkBillingStatusAction = Observable.merge(retryBillingAction.asObservable(), checkBillingStatus.asObservable())
            .flatMap {
                self.useCase.getBillingInfoStatus()
                    .catchError({(error) -> Observable<BillingInfo> in
                        if let error = error as? GooServiceError {
                            switch error {
                            case .sessionTimeOut:
                                return Observable.error(error)
                            case .authenticationError:
                                return Observable.error(error)
                            case .otherError(_):
                                return Observable.error(error)
                            default:
                                return Observable.just(BillingInfo(platform: "", billingStatus: .free))
                            }
                        }
                        return Observable.error(error)
                    })
                    .trackError(errorTrackerBillingStatus)
            }
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (billingInfo) -> Observable<Void> in
                AppManager.shared.billingInfo.accept(billingInfo)
                AppManager.shared.updateSettingSearch(billingStatus: billingInfo)
                self.navigator.toGooLoginView()
                return Observable.just(())
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
       
        return Output(
            tapToMain: tapToMain,
            loading: self.useCase.activityIndicator.asDriver(),
            result: result,
            checkBillingStatusAction: checkBillingStatusAction,
            errorBillingHandler: errorBillingHandler
        )
    }
}

