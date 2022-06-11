//
//  AppViewModel.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct AppViewModel {
    var navigator: AppNavigateProtocol
    var useCase: AppUseCase
    private let disposeBag = DisposeBag()
}

extension AppViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
    }
    
    struct Output {
        let forceUpdate: Driver<Void>
        let toMain: Driver<Void>
        let loading: Driver<Bool>
        let error: Driver<Void>
        let detectUserFree: Driver<Void>
        let errorBillngStatus: Driver<Void>
        let errorListDevices: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        
        let checkVersionTrigger = self.useCase
            .checkVersionAgreement(isHighPriority: useCase.isFirstRun())
            .trackActivity(activityIndicator)
        
        let getUIText = self.useCase.getUIBillingTextValue()
        
        let getBillingStatus = PublishSubject<BillingInfo>.init()
        
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTrackerBillingStatus = ErrorTracker()
        let errorBillingHandler = errorTrackerBillingStatus
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
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .do(onNext: self.navigator.quit)
                            .asDriverOnErrorJustComplete()
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .do(onNext: self.navigator.quit)
                    .asDriverOnErrorJustComplete()
            })

        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let alertForceUpdate = PublishSubject<FileStoreForceUpdate>.init()
        let forceUpdate = Driver.merge(input.loadTrigger, retryAction)
            .asObservable().flatMapLatest {
                self.useCase.getDataForceUpdate()
            }
            .filter({ (object) -> Bool in
                if let obj = object, obj.isForceUpdate() {
                    alertForceUpdate.onNext(obj)
                    return false
                }
                return true
            }).mapToVoid().asDriverOnErrorJustComplete()
        
        let showForceUpdate = alertForceUpdate.flatMap { (obj) -> Observable<Bool> in
            return self.navigator.toForceUpdate(object: obj)
        }.do(onNext: { (isUpdate) in
            if (isUpdate) {
                self.navigator.toAppstore()
            }
        }).asDriverOnErrorJustComplete().mapToVoid()
        
        let toMain = Driver.merge(forceUpdate, retryAction)
            .asObservable()
            .flatMapLatest {
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
                        return Observable.just(BillingInfo(platform: "", billingStatus: .free))
                    })
                    .trackError(errorTrackerBillingStatus)
                    .asDriverOnErrorJustComplete()
            }
            .flatMapLatest { Observable.combineLatest(Observable.just($0), checkVersionTrigger, getUIText) }
            .do(onNext: { (obj) in
                AppManager.shared.billingText = obj.2
                if let date = obj.1, self.useCase.isNewVersion(date: date) {
                    let url = URL(string: GlobalConstant.termURL)!

                    if self.useCase.isFirstRun() {
                        self.navigator.toAgreementView(url: url, dateVersion: date)
                    } else {
                        self.navigator.toReagreementView(url: url, dateVersion: date)
                    }
                } else if self.useCase.isFirstRun() {
                    self.navigator.toTutorial()
                } else if self.useCase.isFirstLogin() || self.useCase.isForceLogout() {
                    self.navigator.toLogin()
                } else {
                    AppManager.shared.billingInfo.accept(obj.0)
                    AppManager.shared.updateSettingSearch(billingStatus: obj.0)
                    
                    //Detect User has SignIn, to check List Device & status Billing
                    if self.useCase.detectUserExist() {
                        getBillingStatus.onNext(obj.0)
                    } else {
                        self.navigator.toMain()
                    }
                }
            })
            .trackError(errorTracker)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        
        let errListDevice = ErrorTracker()
        let doErrListDevice = errListDevice.asObservable().flatMap { err -> Driver<Void> in
            if let error = err as? GooServiceError {
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
                case .otherError(let errorCode):
                    return self.navigator
                        .showMessage(errorCode: errorCode)
                        .do(onNext: self.navigator.quit)
                        .asDriverOnErrorJustComplete()
                default:
                    return Driver.empty()
                }
            }
            
            return self.navigator
                .showMessage(L10n.Server.Error.timeOut)
                .do(onNext: self.navigator.quit)
                .asDriverOnErrorJustComplete()
        }
        .asDriverOnErrorJustComplete()
        
        let limitDevice = GlobalConstant.limitDevice
        let detectUserFree = getBillingStatus
            .flatMapLatest { Observable.combineLatest(Observable.just($0), self.useCase.getListDevice(errTrack: errListDevice).trackError(errListDevice))  }
            .observeOn(MainScheduler.asyncInstance)
            .do { (info, list) in
                if list.count > limitDevice && info.billingStatus == .free {
                    self.navigator.toListDeviceWithCaseOverLimit()
                } else {
                    self.navigator.toMain()
                }
            }
            .asDriverOnErrorJustComplete()
            .mapToVoid()

        let error: Driver<Void>
        if useCase.isFirstRun() {
            error = errorTracker
                .asObservable()
                .flatMapLatest({ (error) -> Observable<Bool> in
                    return self.navigator.toNetworkErrorAlert()
                })
                .filter({ $0 })
                .mapToVoid()
                .do(onNext: self.navigator.quit)
                .asDriverOnErrorJustComplete()
        } else {
            error = errorTracker
                .asObservable()
                .mapToVoid()
                .do(onNext: self.navigator.toMain)
                .asDriverOnErrorJustComplete()
        }
            
        return Output(
            forceUpdate: showForceUpdate,
            toMain: toMain,
            loading: activityIndicator.asDriver(),
            error: error,
            detectUserFree: detectUserFree,
            errorBillngStatus: errorBillingHandler,
            errorListDevices: doErrListDevice
        )
    }
}
