//
//  RegisterDevice.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//
import Foundation
import RxSwift
import RxCocoa

struct RegisterDeviceVM {
    var navigator: RegisterDeviceNavigateProtocol
    var useCase: RegisterDeviceUseCase
    private let disposeBag = DisposeBag()
}

extension RegisterDeviceVM: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
        let tapToMain: Driver<TapRegisterScreen>
        let deleteDevice: Driver<DeviceInfo>
        let registerDevice: Driver<String>
        let isRemoveLoginScreen: Driver<Void>
        let autoMoveHome: Driver<Bool>
        let dismissTrigger: Driver<Void>
    }
    
    struct Output {
        let tapToMain: Driver<TapRegisterScreen>
        let deleteDevice: Driver<Void>
        let registerDevice: Driver<Void>
        let deviceName: Driver<String>
        let err: Driver<Void>
        let errName: Driver<Void>
        let getlistTheDevice: Driver<Void>
        let listDevice: Driver<[DeviceInfo]>
        let loading: Driver<Bool>
        let doErrService: Driver<Void>
        let retryAction: Driver<Void>
        let retryActionName: Driver<Void>
        let isRemoveLoginScreen: Driver<Void>
        let retrySession: Driver<Void>
        let getListDeviceAfterActionDelete: Driver<Void>
        let autoMoveHome: Driver<Void>
        let checkBillingStatus: Driver<Void>
        let errorHandlerBilling: Driver<Void>
        let dismissTrigger: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        var countRetry: Int = 0
        var countName: Int = 0
        
        
        let tapToMain = input.tapToMain.do { type in
            switch type {
            case .ignore:
                self.navigator.toGooLoginView()
            default:
                countRetry = 0
                break
            }
        }
        
        let errTrack = ErrorTracker()
        let doErrorService = PublishSubject<Error>.init()
        let retryCount = PublishSubject<Int>.init()
        let retryCountName = PublishSubject<Int>.init()
        let retryAddName = PublishSubject<String>.init()
        let retryDeleteDevice = PublishSubject<DeviceInfo>.init()
        let errTrackName = ErrorTracker()
        let listDeviceUpdate = PublishSubject<[DeviceInfo]>.init()
        let updateName = PublishSubject<String>.init()
        let fullDevices = PublishSubject<Void>.init()
        let getListDevice = PublishSubject<Void>.init()
        
        let delete = input.deleteDevice
            .asObservable()
            .flatMap { d in self.useCase.deleteDevice(device: d)
                .trackError(errTrack)
                .mapToVoid()
                .asDriverOnErrorJustComplete()
            }
            
        let register = input.registerDevice
            .asObservable()
            .flatMap{ name in self.useCase.addDevice(name: name)
                .trackError(errTrack)
                .asDriverOnErrorJustComplete()
                .do(onNext: self.navigator.toGooLoginView )
            }
            
        
        let deviceName = input
            .loadTrigger
            .asObservable()
            .flatMap { self.useCase.getNameDevice()
                .trackError(errTrackName)
                .asDriverOnErrorJustComplete()
            }
        
        let errorTracker = ErrorTracker()
        let errorHandlerBilling = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Menu.Error.RegisterDevice.maintenance)
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
        
        let checkBillingStatus = input
            .loadTrigger
            .asObservable()
            .flatMap { self.useCase.getBillingInfoStatus().trackError(errorTracker) }
            .do(onNext: { (obj) in
                AppManager.shared.billingInfo.accept(obj)
                AppManager.shared.updateSettingSearch(billingStatus: obj)
                getListDevice.onNext(())
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        
        let getlistTheDevice = getListDevice
            .asObservable()
            .flatMap { self.useCase.getListDevice()
                .trackError(errTrack)
                .asDriverOnErrorJustComplete()
            }
            .flatMap({ (list) -> Observable<Void> in
                listDeviceUpdate.onNext(list)
                return Observable.just(())
            })
            .asDriverOnErrorJustComplete()
        
        let listDevice = listDeviceUpdate
            .asObservable()
            .flatMap { (list) -> Observable<[DeviceInfo]> in
                guard let device_id = UIDevice.current.identifierForVendor?.uuidString else {
                    return Observable.empty()
                }
                var userInfo = AppManager.shared.userInfo.value
                if list.count == 0 {
                    userInfo?.deviceStatus = .unregistered
                }
                for d in list {
                    if d.id == device_id {
                        userInfo?.deviceStatus = .registered
                        AppManager.shared.userInfo.accept(userInfo)
                        return Observable.just(list)
                    } else {
                        userInfo?.deviceStatus = .unregistered
                    }
                }
                AppManager.shared.userInfo.accept(userInfo)
                return Observable.just(list)
            }
            .asDriverOnErrorJustComplete()
    
        let getName = Observable.merge(deviceName.asObservable(), updateName.asObservable()).asDriverOnErrorJustComplete()
        
        let retryAction = retryCount.asObservable()
            .filter { $0 < 2 }
            .withLatestFrom(input.tapToMain.startWith(.getListDevice), resultSelector: { (_, type) -> (TapRegisterScreen) in
                return type
            })
            .flatMap { (type) -> Observable<Void> in
                switch type {
                case .getListDevice:
                    return self.useCase.getListDevice()
                        .trackError(errTrack)
                        .mapToVoid()
                case .addDevice(let name):
                    retryAddName.onNext(name)
                    return Observable.just(())
                case .removeDevice(let deviceInfo):
                    retryDeleteDevice.onNext(deviceInfo)
                    return Observable.just(())
                default:
                    return Observable.just(())
                }
            }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let retryActionName = retryCountName.asObservable()
            .filter { $0 < 2 }
            .flatMap { _ in self.useCase.getNameDevice().trackError(errTrackName) }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let retryActionAddName = retryAddName
            .asObservable()
            .flatMap { name in return self.useCase.addDevice(name: name)
                .trackError(errTrack)
                .asDriverOnErrorJustComplete()
                .do(onNext: self.navigator.toGooLoginView )
            }
            .observeOn(MainScheduler.asyncInstance)
        
        let retryActionDeleteDevice = retryDeleteDevice.asObservable()
            .flatMap { (d) -> Driver<Void> in
                return self.useCase.deleteDevice(device: d)
                    .trackError(errTrack)
                    .mapToVoid()
                    .asDriverOnErrorJustComplete()
            }
        
        let err = errTrack
            .asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .flatMap { err -> Observable<Void> in
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
                            .do { _ in
                            countRetry += 1
                            retryCount.onNext(countRetry)
                        }
                    case .fullDevices:
                        
                        fullDevices.onNext(())
                        
                        return Observable.just(())
                    default:
                        doErrorService.onNext(error)
                        return Observable.just(())
                    }
                }
                doErrorService.onNext(err)
                return Observable.just(())
            }
            .asDriverOnErrorJustComplete()
        
        let errName = errTrackName
            .asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .flatMap { err -> Observable<Void> in
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
                            .do { _ in
                            countName += 1
                            retryCountName.onNext(countRetry)
                        }
                    case .fullDevices:
                        
                        fullDevices.onNext(())
                        
                        return Observable.just(())
                    default:
                        doErrorService.onNext(error)
                        return Observable.just(())
                    }
                }
                doErrorService.onNext(err)
                return Observable.just(())
            }.asDriverOnErrorJustComplete()
        
        let doErrService = doErrorService.asObservable()
            .observeOn(MainScheduler.instance)
            .flatMap { err -> Observable<Void> in
                if let error = err as? GooServiceError {
                    switch error {
                    case .maintenance:
                        return self.navigator.showMessage(L10n.ErrorDevice.Error.maintenance)
                    case .maintenanceCannotUpdate(let data):
                        if let list = data as? [DeviceInfo] {
                            listDeviceUpdate.onNext(list)
                        }
                        
                        if let name = data as? String {
                            updateName.onNext(name)
                        }
                        
                        return self.navigator.showMessage(L10n.ErrorDevice.Error.maintenance)
                    case .authenticationError:
                        return self.useCase.logout()
                            .do(onNext: self.navigator.toForceLogout)
                    case .otherError(let errorCode):
                        return self.navigator.showMessage(errorCode: errorCode)
                    default:
                        return Observable.just(())
                    }
                }
                return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)
            }
            .flatMap({ _ -> Observable<Void> in
                self.navigator.toGooLoginView()
                return Observable.just(())
            })
            .asDriverOnErrorJustComplete()
        
        let isRemoveLoginScreen = input.isRemoveLoginScreen
            .asObservable()
            .flatMap { self.navigator.toRemoveLogin() }
            .asDriverOnErrorJustComplete()
        
        let trackActivity = self.useCase.trackActivity
        
        let refreshLimit = fullDevices.asObservable()
            .flatMap { self.useCase.getListDevice()
                .trackError(errTrack)
                .asDriverOnErrorJustComplete() }
            .flatMap { (list) -> Observable<Void> in
                listDeviceUpdate.onNext(list)
                return Observable.just(())
            }
        
        let refrshName = fullDevices.asObservable()
            .flatMap { self.useCase.getNameDevice()
                .trackError(errTrackName)
                .asDriverOnErrorJustComplete()
            }
            .flatMap { (name) -> Observable<Void> in
                updateName.onNext(name)
                return Observable.just(())
            }
        
        let retrySession = Observable.merge(self.useCase.getListDevice().trackError(errTrack).mapToVoid(),
                                            retryActionAddName,
                                            refreshLimit.mapToVoid(),
                                            refrshName.mapToVoid(),
                                            self.useCase.getNameDevice().trackError(errTrackName).mapToVoid())
            .asDriverOnErrorJustComplete()
        
        let deleteAction = Observable.merge(delete.asObservable(), retryActionDeleteDevice).asDriverOnErrorJustComplete()
        
        let getListDeviceAfterActionDelete = deleteAction
            .asObservable()
            .flatMap { self.useCase.getListDevice()
                .trackError(errTrack)
                .asDriverOnErrorJustComplete()
            }
            .flatMap({ (list) -> Observable<Void> in
                listDeviceUpdate.onNext(list)
                return Observable.just(())
            })
            .asDriverOnErrorJustComplete()
        
        let autoMoveHome = input.autoMoveHome
            .filter{ $0 == true }
            .do { _ in self.navigator.toGooLoginView() }
            .mapToVoid()
        
        let dismissTrigger = input.dismissTrigger
            .do { _ in
                self.navigator.toGooLoginView()
            }
        
        return Output(
            tapToMain: tapToMain,
            deleteDevice: deleteAction,
            registerDevice: register.asDriverOnErrorJustComplete(),
            deviceName: getName,
            err: err,
            errName: errName,
            getlistTheDevice: getlistTheDevice,
            listDevice: listDevice,
            loading: trackActivity.asDriver(),
            doErrService: doErrService,
            retryAction: retryAction,
            retryActionName: retryActionName,
            isRemoveLoginScreen: isRemoveLoginScreen,
            retrySession: retrySession,
            getListDeviceAfterActionDelete: getListDeviceAfterActionDelete,
            autoMoveHome: autoMoveHome,
            checkBillingStatus: checkBillingStatus,
            errorHandlerBilling: errorHandlerBilling,
            dismissTrigger: dismissTrigger
        )
    }
}


