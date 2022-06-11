//
//  LoginViewModel.swift
//  GooDic
//
//  Created by paxcreation on 11/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import GooidSDK

struct LoginViewModel {
    var navigator: LoginNavigateProtocol
    var useCase: LoginUseCase
    private let disposeBag = DisposeBag()
}

extension LoginViewModel: ViewModelProtocol {
    struct Input {
        let tapAction: Driver<TypeGooIDSKD>
    }
    
    struct Output {
        let tap: Driver<Void>
        //        let status: Driver<Void>
        let err: Driver<Void>
        let errNetwork: Driver<Void>
        let loading: Driver<Bool>
        let result: Driver<Void>
        let doErrorListDevice: Driver<Void>
        let checkRegisterMenuScreen: Driver<Void>
        let checkRegisterCannotBeUpdate: Driver<Void>
        let updateWaitingAPI: Driver<Void>
        let retryListDevice: Driver<Void>
        let checkBillingAction: Driver<Void>
        let errorBillingHandle: Driver<Void>
        let doMoveToDevicesWithCaseOverLimit: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        var countRetry: Int = 0
        let checkRegisterMenu = PublishSubject<Void>.init()
        let waitingAPIListDevice = BehaviorRelay<Bool>.init(value: false)
        let retryGetList: PublishSubject<Void> = PublishSubject.init()
        let checkBillingStatus = PublishSubject<Void>.init()
        let moveToDevicesWithCaseOverLimit = PublishSubject<Void>.init()
        
        let tapOnScreen = input
            .tapAction
            .flatMap({ type -> Driver<Void> in
                switch type {
                case .ignore:
                    self.useCase.loggined()
                    self.navigator.toGooLoginView()
                    if GooidSDK.sharedInstance.gooidTicket()?.httpsCookies != nil {
                        return self.useCase.logout().asDriverOnErrorJustComplete()
                    } else {
                        return Driver.just(())
                    }
                default:
                    countRetry = 0
                    self.useCase.validateServer()
                    return Driver.just(())
                }
            })
        
        let errNetwork = self.useCase.erroNetwork
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (err) -> Observable<Void> in
                return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)
                
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let statusServer = self.useCase.statusServer.observeOn(MainScheduler.asyncInstance)
        let errGetListDevice = ErrorTracker()
        let statusCanotBeUpdate = PublishSubject<GooServiceError>.init()
        let statusCannotBeUpdateMenu = PublishSubject<[DeviceInfo]>.init()
        
        
        let errServer = self.useCase.statusServerError
            .observeOn(MainScheduler.asyncInstance)
            .withLatestFrom(input.tapAction, resultSelector: { (err, type) -> (GooServiceError, TypeGooIDSKD) in
                return (err, type)
            })
            .flatMap({ (err) -> Observable<Void> in
                switch err.0 {
                case .maintenance:
                    switch self.navigator.routeLoginNavi {
                    case .cloudDraft, .cloudFolder, .cloudFolderSelection, .menu:
                        return self.navigator.showMessage(L10n.Menu.Error.Login.maintenance)
                    default:
                        return self.navigator.showMessage(L10n.Login.Server.Error.maintain)
                    }
                case .maintenanceCannotUpdate(_):
                    switch err.1 {
                    case .register:
                        switch self.navigator.routeLoginNavi {
                        case .cloudDraft, .cloudFolder, .cloudFolderSelection, .menu:
                            return self.navigator.showMessage(L10n.Menu.Error.Login.maintenance)
                        default:
                            return self.navigator.showMessage(L10n.Login.Server.Error.maintain)
                        }
                    case .login:
                        switch self.navigator.routeLoginNavi {
                        case .app, .tutorial, .login:
                            return self.navigator.showMessage(L10n.Login.Server.Error.maintain)
                        default:
                            statusCanotBeUpdate.onNext(err.0)
                            return Observable.just(())
                        }
                    default:
                        return Observable.just(())
                    }
                case .otherError(let errorCode):
                    return self.navigator.showMessage(errorCode: errorCode)
                default:
                    return Observable.just(())
                }
            }).mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let doStatusCanotBeUpdate = statusCanotBeUpdate
            .asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .flatMap({ (err) -> Observable<Void> in
                switch self.navigator.routeLoginNavi {
                case .cloudFolder, .cloudDraft, .cloudFolderSelection:
                    return self.navigator.showMessage(L10n.Login.Server.Error.cannotBeUpdate)
                default:
                    return self.navigator.showMessage(L10n.Login.Server.Error.cannotBeUpdate)
                }
            }).mapToVoid()
        
        let result = Observable.merge(statusServer, doStatusCanotBeUpdate)
            .withLatestFrom(input.tapAction.asObservable(), resultSelector: { (_, type) -> Driver<GooIDResult> in
                switch type {
                case .login:
                    switch self.navigator.routeLoginNavi {
                    case .menu, .cloudDraft, .cloudFolder, .cloudFolderSelection, .app, .tutorial, .login:
                        waitingAPIListDevice.accept(false)
                        return  self.useCase.login(waitingAPIListDevice: waitingAPIListDevice).asDriverOnErrorJustComplete()
                    default:
                        return  self.useCase.login(waitingAPIListDevice: nil).asDriverOnErrorJustComplete()
                    }
                case .register:
                    return self.useCase.register().asDriverOnErrorJustComplete()
                case .ignore:
                    return Driver.just(GooIDResult.cancel)
                }
            })
            .flatMap { $0 }
            .withLatestFrom(input.tapAction.asObservable(), resultSelector: { (result, type) -> Observable<Void> in
                switch type {
                case .register:
                    switch result {
                    case .success:
                        self.useCase.loggined()
                        self.navigator.moveToRegisterScreenWhenTapRegister()
                    default:
                        break
                    }
                    return Observable.just(())
                case .login:
                    //There are 2 cases
                    //with case what isnot app - login - tutorial, App will call api get list to check device
                    switch result {
                    case .success:
                        self.useCase.sendAFEventLoginSuccess()
                        self.useCase.loggined()
                        switch self.navigator.routeLoginNavi {
                        case .menu, .cloudDraft, .cloudFolder, .cloudFolderSelection, .app, .login, .tutorial:
                            checkRegisterMenu.onNext(())
                        default:
                            AppManager.shared.updateRegisteredDeviceStatus(errGetListDevice)
                            self.navigator.toRegisterDevice()
                        }
                    default:
                        break
                    }
                    return Observable.just(())
                case .ignore:
                    return Observable.just(())
                }
            })
            .flatMap { $0 }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let updateWaitingAPI = errGetListDevice
            .asObservable()
            .flatMap({ (err) -> Observable<Void> in
                if let error = err as? GooServiceError {
                    switch error {
                    case .maintenanceCannotUpdate(_):
                        return Observable.just(())
                    default:
                        waitingAPIListDevice.accept(true)
                        return Observable.just(())
                    }
                }
                waitingAPIListDevice.accept(true)
                return self.navigator.showMessage(from: self.navigator.viewcontroller, message: L10n.Login.Server.Error.timeOut)
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let doErrorListDevice = errGetListDevice
            .asObservable()
            .flatMap({ (err) -> Observable<Void> in
                if let error = err as? GooServiceError {
                    switch error {
                    case .maintenance:
                        switch self.navigator.routeLoginNavi {
                        case .app, .login, .tutorial:
                            return self.navigator.showMessage(L10n.Menu.Error.Login.maintenance)
                        default:
                            return self.navigator.showMessage(from: self.navigator.viewcontroller, message: L10n.Menu.Error.Login.maintenance)
                        }
                    case .maintenanceCannotUpdate(let list):
                        switch self.navigator.routeLoginNavi {
                        case .cloudFolderSelection:
                            return self.navigator.showMessage(from: self.navigator.viewcontroller, message: L10n.ListDevivice.Server.Error.cannotBeUpdate)
                        case .menu, .app, .login, .tutorial:
                            if let list = list as? [DeviceInfo] {
                                statusCannotBeUpdateMenu.onNext(list)
                            } else {
                                waitingAPIListDevice.accept(true)
                                self.navigator.popViewController()
                            }
                            return Observable.just(())
                        default:
                            return Observable.just(())
                        }
                    case .authenticationError:
                        return self.useCase.logout()
                            .observeOn(MainScheduler.asyncInstance)
                            .do(onNext: self.navigator.toForceLogout)
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
                            if countRetry < 2 {
                                retryGetList.onNext(())
                            }
                        }
                    case .otherError(let errorCode):
                        switch self.navigator.routeLoginNavi {
                        case .app, .login, .tutorial:
                            return self.navigator.showMessage(errorCode: errorCode,
                                                              message: L10n.Server.Error.Other.message,
                                                              hyperlink: L10n.Server.Error.Other.hyperlink,
                                                              link: GlobalConstant.errorInfoURL)
                        default:
                            return self.navigator.showMessage(from: self.navigator.viewcontroller,
                                                              errorCode: errorCode,
                                                              message: L10n.Server.Error.Other.message,
                                                              hyperlink: L10n.Server.Error.Other.hyperlink,
                                                              link: GlobalConstant.errorInfoURL)
                        }
                        
                    default:
                        return Observable.just(())
                    }
                }
                switch self.navigator.routeLoginNavi {
                case .app, .login, .tutorial:
                    return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)
                default:
                    return self.navigator.showMessage(from: self.navigator.viewcontroller, message: L10n.Login.Server.Error.timeOut)
                }
                
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let retryListDevice = retryGetList.asObservable()
            .flatMap { self.useCase.getListDevice().trackError(errGetListDevice) }
            .flatMap({ (list) -> Observable<Bool> in
                guard let device_id = UIDevice.current.identifierForVendor?.uuidString else {
                    return Observable.empty()
                }
                var userInfo = UserInfo(name: "", deviceStatus: .unknown, billingStatus: .free)
                let link = list.first(where: { $0.id == device_id })
                userInfo.deviceStatus = (link == nil) ? DeviceStatus.unregistered : DeviceStatus.registered
                AppManager.shared.userInfo.accept(userInfo)
                
                waitingAPIListDevice.accept(true)
                
                return Observable.just(userInfo.deviceStatus == .registered)
            })
            .observeOn(MainScheduler.asyncInstance)
            .flatMap { isRegister in  self.navigator.moveToRegister(isRegister: isRegister) }
        
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
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                                
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                    case .otherError(let errorCode):
                        switch self.navigator.routeLoginNavi {
                        case .app, .login, .tutorial:
                            return self.navigator.showMessage(errorCode: errorCode,
                                                              message: L10n.Server.Error.Other.message,
                                                              hyperlink: L10n.Server.Error.Other.hyperlink,
                                                              link: GlobalConstant.errorInfoURL)
                        default:
                            return self.navigator.showMessage(from: self.navigator.viewcontroller,
                                                              errorCode: errorCode,
                                                              message: L10n.Server.Error.Other.message,
                                                              hyperlink: L10n.Server.Error.Other.hyperlink,
                                                              link: GlobalConstant.errorInfoURL)
                        }
                        
                    default:
                        return Observable.just(())
                    }
                }
    
                switch self.navigator.routeLoginNavi {
                case .app, .login, .tutorial:
                    return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)
                default:
                    return self.navigator.showMessage(from: self.navigator.viewcontroller, message: L10n.Login.Server.Error.timeOut)
                }
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let retryBillingAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let checkBillingStatusAction = Observable.merge(checkBillingStatus.asObservable(), retryBillingAction.asObservable())
            .flatMap {
                self.useCase.getBillingInfoStatus()
                    .catchError({(error) -> Observable<BillingInfo> in
                        waitingAPIListDevice.accept(true)
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
                    .asDriverOnErrorJustComplete()
            }
            .do(onNext: { (obj) in
                AppManager.shared.billingInfo.accept(obj)
                AppManager.shared.updateSettingSearch(billingStatus: obj)
                
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let eventDetectListDeviceWeb = PublishSubject<DeviceInfo>.init()
        let doEventDetectListDeviceWeb = eventDetectListDeviceWeb
            .flatMap{ self.useCase.deleteDevice(device: $0).trackError(errGetListDevice) }
            .flatMap{ self.useCase.getListDevice().trackError(errGetListDevice) }
        
        let checkRegisterMenuScreen = Observable.merge(retryGetList.asObservable(), checkRegisterMenu.asObservable())
            .flatMap {
                self.useCase.getBillingInfoStatus()
                    .catchError({(error) -> Observable<BillingInfo> in
                        waitingAPIListDevice.accept(true)
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
            .flatMapLatest { Observable.combineLatest(Observable.just($0),
                                                      Observable.merge(self.useCase.getListDevice().trackError(errGetListDevice),
                                                                       doEventDetectListDeviceWeb.asObservable()
                                                                       )) }
            .flatMap({ (obj) -> Observable<Bool> in
                AppManager.shared.billingInfo.accept(obj.0)
                AppManager.shared.updateSettingSearch(billingStatus: obj.0)
                GATracking.sendUserPropertiesAfterLogin(userIdForGA: GooidSDK.sharedInstance.gooidTicket()?.userIdForGA)
                
                if (obj.1.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) != nil) && obj.0.billingStatus == .free {
                    if let index = obj.1.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) {
                        eventDetectListDeviceWeb.onNext(obj.1[index])
                    }
                    return Observable.empty()
                }
                
                guard let device_id = UIDevice.current.identifierForVendor?.uuidString else {
                    return Observable.empty()
                }
                
                var userInfo = UserInfo(name: "", deviceStatus: .unknown, billingStatus: obj.0.billingStatus)
                let link = obj.1.first(where: { $0.id == device_id })
                userInfo.deviceStatus = (link == nil) ? DeviceStatus.unregistered : DeviceStatus.registered
                AppManager.shared.userInfo.accept(userInfo)
                
                if obj.1.count > GlobalConstant.limitDevice && obj.0.billingStatus == .free {
                    moveToDevicesWithCaseOverLimit.onNext(())
                    waitingAPIListDevice.accept(true)
                    return Observable.empty()
                }
                
                waitingAPIListDevice.accept(true)
                
                return Observable.just(userInfo.deviceStatus == .registered)
            })
            .observeOn(MainScheduler.asyncInstance)
            .flatMap { isRegister in  self.navigator.moveToRegister(isRegister: isRegister) }
        
        let eventDetectListDeviceWebCannot = PublishSubject<DeviceInfo>.init()
        let doEventDetectListDeviceWebCannot = eventDetectListDeviceWebCannot
            .flatMap{ self.useCase.deleteDevice(device: $0).trackError(errGetListDevice) }
            .flatMap{ self.useCase.getListDevice().trackError(errGetListDevice) }
        
        let checkRegisterCannotBeUpdate = Observable.merge(statusCannotBeUpdateMenu.asObservable(),
                                                           doEventDetectListDeviceWebCannot.asObservable()
                                                           )
            .flatMap({ (list) -> Observable<Bool> in
                
                if (list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) != nil) &&
                    AppManager.shared.billingInfo.value.billingStatus == .free {
                    if let index = list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) {
                        eventDetectListDeviceWebCannot.onNext(list[index])
                    }
                    return Observable.empty()
                }
                
                guard let device_id = UIDevice.current.identifierForVendor?.uuidString else {
                    return Observable.empty()
                }
                var userInfo = UserInfo(name: "", deviceStatus: .unknown, billingStatus: .free)
                let link = list.first(where: { $0.id == device_id })
                userInfo.deviceStatus = (link == nil) ? DeviceStatus.unregistered : DeviceStatus.registered
                AppManager.shared.userInfo.accept(userInfo)
                
                if list.count > GlobalConstant.limitDevice && AppManager.shared.billingInfo.value.billingStatus == .free {
                    moveToDevicesWithCaseOverLimit.onNext(())
                    waitingAPIListDevice.accept(true)
                    return Observable.empty()
                }
                
                waitingAPIListDevice.accept(true)
                
                return Observable.just(userInfo.deviceStatus == .registered)
            })
            .observeOn(MainScheduler.asyncInstance)
            .flatMap { isRegister in  self.navigator.moveToRegister(isRegister: isRegister) }
        
        let doMoveToDevicesWithCaseOverLimit = moveToDevicesWithCaseOverLimit
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: self.navigator.toListDeviceWithCaseOverLimit )
            .asDriverOnErrorJustComplete()
        
        return Output(
            tap: tapOnScreen,
            //            status: status,
            err: errServer,
            errNetwork: errNetwork,
            loading: self.useCase.activityIndicator.asDriver(),
            result: result,
            doErrorListDevice: doErrorListDevice,
            checkRegisterMenuScreen: checkRegisterMenuScreen.asDriverOnErrorJustComplete(),
            checkRegisterCannotBeUpdate: checkRegisterCannotBeUpdate.asDriverOnErrorJustComplete(),
            updateWaitingAPI: updateWaitingAPI,
            retryListDevice: retryListDevice.asDriverOnErrorJustComplete(),
            checkBillingAction: checkBillingStatusAction,
            errorBillingHandle: errorBillingHandler,
            doMoveToDevicesWithCaseOverLimit: doMoveToDevicesWithCaseOverLimit
        )
    }
}

