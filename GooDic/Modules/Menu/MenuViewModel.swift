//
//  MenuViewModel.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//
import Foundation
import RxSwift
import RxCocoa
import GooidSDK

struct MenuViewModel {
    let useCase: MenuUseCaseProtocol
    let navigator: MenuNavigateProtocol
    let rawData: [MenuData]
    
    init(data: [MenuData], useCase: MenuUseCaseProtocol, navigator: MenuNavigateProtocol) {
        self.rawData = data
        self.useCase = useCase
        self.navigator = navigator
    }
}

extension MenuViewModel: ViewModelProtocol {    
    struct Input {
        let loadTrigger: Driver<Void>
        let viewWillAppear: Driver<Void>
        let viewWillDisappear: Driver<Void>
        let actionTrigger: Driver<Void> // login or logout
        let devicesTrigger: Driver<Void>
        let selectCellTrigger: Driver<IndexPath>
        let selectFrameTrigger: Driver<CGRect?>
        let rotateTrigger: Driver<Void>
        let accountInfoTrigger: Driver<Void>
        let eventUpdate: Driver<Void>
    }
    
    struct Output {
        let data: Driver<[MenuData]>
        let selectedCell: Driver<MenuAction>
        let getUserName: Driver<Void>
        let loginLogoutAccount: Driver<Void>
        let presentedDevices: Driver<Void>
        let updatedUIAfterRotation: Driver<Void>
        let showLoading: Driver<Bool>
        let accountInfoAction: Driver<Void>
        let checkBillingStatus: Driver<Void>
        let detectUserFree: Driver<Void>
        let isValidatingServer: Driver<Bool>
        let eventUpdate: Driver<Void>
        let doErrDevices: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    private func getMenuItem() -> [MenuData] {
        if AppManager.shared.billingInfo.value.billingStatus == .paid {
            return rawData.filter { $0.sceneType != GATracking.Scene.requestPremium }
        }
        return rawData
    }
    
    func transform(_ input: Input) -> Output {

        let isValidatingServer = BehaviorRelay<Bool>(value: false)
        
        let billingInfo = AppManager.shared.billingInfo.asDriver().mapToVoid()
        let data = Driver
            .merge(
                input.loadTrigger,
                billingInfo)
            .map({getMenuItem()})
            .asDriver()

        let selectedData = input.selectCellTrigger
            .withLatestFrom(data) { ($0, $1) }
            .filter ({ (indexPath, items) -> Bool in
                indexPath.row < items.count
            })
            .map ({ (indexPath, items) -> MenuData in
                return items[indexPath.row]
            })
            
        let selectedCell = selectedData
            .withLatestFrom(input.selectFrameTrigger, resultSelector: { (data: $0, rect: $1) })
            .do(onNext: { (obj) in
                switch obj.data.action {
                case let .openWebView(urlString, cachePolicy, links):
                    if let url = URL(string: urlString) {
                        self.navigator.toWebView(url: url, cachePolicy: cachePolicy, title: obj.data.title, sceneType: obj.data.sceneType, internalLinkDatas: links)
                    }
                case let .share(urlString):
                    if let url = URL(string: urlString) {
                        self.navigator.toShareView(url: url, rect: obj.rect)
                    } else {
                        self.navigator.toShareStringView(content: urlString, rect: obj.rect)
                    }
                case .openTrash:
                    self.navigator.toTrash()
                    break
                case .registerSubscription:
                    self.navigator.toRequestPremium()
                case .openGooTwitter:
                    self.navigator.toGooTwitter()
                    break
                case .openSetting:
                    self.navigator.toSettingEnviromental()
                    break
                }
            })
            .map({ $0.data.action })
        
        let updatedUIAfterRotation = input.rotateTrigger
            .withLatestFrom(input.selectFrameTrigger)
            .do(onNext: self.navigator.updateShareView(rect:))
            .mapToVoid()
        
        let activityIndicator = ActivityIndicator()
        let startNewAction = PublishSubject<Void>()
        let cancelTrigger = Driver.merge(input.viewWillDisappear, startNewAction.asDriverOnErrorJustComplete())
        
        let loginLogoutAccount = showLoginFlow(tap: input.actionTrigger,
                                               startNewAction: startNewAction,
                                               cancelTrigger: cancelTrigger,
                                               isValidatingServer: isValidatingServer)
        let presentedDevices = showRegisterDevicesFlow(tap: input.devicesTrigger,
                                                       startNewAction: startNewAction,
                                                       cancelTrigger: cancelTrigger)
        
        let eventListDevice: PublishSubject<[DeviceInfo]> = PublishSubject.init()
        let checkListDevice: PublishSubject<Bool> = PublishSubject.init()
        let getBillingStatus = PublishSubject<BillingInfo>.init()
        let checkBillingInfo: PublishSubject<Bool> = PublishSubject.init()
        
        let checkBillingStatus = getBillingStatusFlow(start: input.viewWillAppear,
                                                      getBillingStatus: getBillingStatus,
                                                      checkBillingInfo: checkBillingInfo)
        let getUserName = getUserNameFlow(start: input.viewWillAppear,
                                          eventListDevice: eventListDevice,
                                          checkListDevice: checkListDevice)
        
        let errListDevice = ErrorTracker()
        let doErrListDevice = errListDevice.asObservable().flatMap { err -> Driver<Void> in
            if let error = err as? GooServiceError {
                switch error {
                case .maintenanceCannotUpdate(_):
                    return Driver.empty()
                case .maintenance:
                    return Driver.empty()
                case .sessionTimeOut:
                    return useCase.refreshSession()
                        .catchError({ (error) -> Observable<Void> in
                            return self.navigator
                                .showMessage(L10n.Sdk.Error.Refresh.session)
                                .observeOn(MainScheduler.instance)
                                .do(onNext: self.navigator.toForceLogout)
                                .flatMap({ Observable.empty() })
                        })
                        .asDriverOnErrorJustComplete()
                    
                case .authenticationError:
                    // navigate to the forced logout screen without displaying an error message
                    return self.useCase.logout()
                        .subscribeOn(MainScheduler.instance)
                        .do(onNext: self.navigator.toForceLogout)
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
        }

        let updateList = Observable.merge(eventListDevice,
                                          AppManager.shared.detectFinalListDevice
                                          )
        
        let limitDevice = GlobalConstant.limitDevice
        let detectUserFree = Driver.combineLatest(updateList.asDriverOnErrorJustComplete(),
                                                  getBillingStatus.asDriverOnErrorJustComplete(),
                                                  checkListDevice.asDriverOnErrorJustComplete(),
                                                  checkBillingInfo.asDriverOnErrorJustComplete()
        )
            
            .do { (list, info, listDevice, billingInfo) in
                
                let listUpdate = list
                
                if (listUpdate.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) != nil) && info.billingStatus == .free && listDevice && billingInfo {
                    AppManager.shared.detectListDeviceWeb(errTrack: errListDevice)
                    return
                }
                
                
                if GooidSDK.sharedInstance.generateCookies() != nil {
                    if listUpdate.count > limitDevice && info.billingStatus == .free && listDevice && billingInfo {
                        self.navigator.toListDevice()
                        checkListDevice.onNext(false)
                        checkBillingInfo.onNext(false)
                    }
                }
            }
            .mapToVoid()
        
        
        let accountInfoAction = input.accountInfoTrigger.do(onNext: { self.navigator.toAccountInfo()
        })
        .mapToVoid()
        
        let eventUpdate = input.eventUpdate
            .asObservable()
            .map({ _ -> Void in
                checkListDevice.onNext(false)
                checkBillingInfo.onNext(false)
                return ()
            })
            .asDriverOnErrorJustComplete()
      

        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .do { _ in
                if AppManager.shared.getCurrentScene() == .menu {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                }
            }
            .asDriverOnErrorJustComplete().mapToVoid()
        
        return Output(
            data: data,
            selectedCell: selectedCell,
            getUserName: getUserName,
            loginLogoutAccount: loginLogoutAccount,
            presentedDevices: presentedDevices,
            updatedUIAfterRotation: updatedUIAfterRotation,
            showLoading: activityIndicator.asDriver(),
            accountInfoAction: accountInfoAction,
            checkBillingStatus: checkBillingStatus,
            detectUserFree: detectUserFree,
            isValidatingServer: isValidatingServer.asDriver(),
            eventUpdate: eventUpdate,
            doErrDevices: doErrListDevice.asDriverOnErrorJustComplete(),
            showPremium: showPremium
        )
    }
    
    private func getBillingStatusFlow(start: Driver<Void>,
                                      getBillingStatus: PublishSubject<BillingInfo>,
                                      checkBillingInfo: PublishSubject<Bool>) -> Driver<Void> {
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTracker = ErrorTracker()
        let billingErrorHandler = errorTracker
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
                        return self.navigator.showMessage(errorCode: errorCode,
                                                          message: L10n.Server.Error.Other.message,
                                                          hyperlink: L10n.Server.Error.Other.hyperlink,
                                                          link: GlobalConstant.errorInfoURL)
                        
                    default:
                        return Observable.just(())
                    }
                }
    
                return self.navigator.showMessage(L10n.Login.Server.Error.timeOut)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let checkBillingStatus = Driver.merge(start, retryAction)
            .asObservable()
            .do(onNext: { _ in
                retry.accept(0)
            })
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
                .trackError(errorTracker)
                .asDriverOnErrorJustComplete()
            }
            .do(onNext: { (obj) in
                getBillingStatus.onNext(obj)
                checkBillingInfo.onNext(true)
                AppManager.shared.billingInfo.accept(obj)
                AppManager.shared.updateSettingSearch(billingStatus: obj)
            })
            .asDriverOnErrorJustComplete()
        
        return Driver.merge(checkBillingStatus.mapToVoid(), billingErrorHandler.asDriverOnErrorJustComplete(), retryAction)
    }
    
    private func getUserNameFlow(start: Driver<Void>,
                                 eventListDevice: PublishSubject<[DeviceInfo]>,
                                 checkListDevice: PublishSubject<Bool>) -> Driver<Void> {
        let retry = BehaviorRelay<Int>(value: 0)
        let userNameErrorTracker = ErrorTracker()
        let userNameErrorHandler = userNameErrorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance(let data):
                        if var userInfo = AppManager.shared.userInfo.value {
                            userInfo.name = data
                            
                            AppManager.shared.userInfo.accept(userInfo)
                        } else {
                            let userInfo = UserInfo(name: data, deviceStatus: .unknown, billingStatus: .free)
                            
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Menu.Error.DeviceStatus.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate(let data):
                        if let name = data as? String, var userInfo = AppManager.shared.userInfo.value {
                            userInfo.name = name
                            
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        // continue without displaying an error message
                        return Driver.just(())
                        
                    case .sessionTimeOut:
                        return useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                        
                    case .authenticationError:
                        // navigate to the forced logout screen without displaying an error message
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
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
        
        let deviceStatusErrorTracker = ErrorTracker()
        let deviceStatusErrorHandler = deviceStatusErrorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Menu.Error.DeviceStatus.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate(let data):
                        if let name = data as? String, var userInfo = AppManager.shared.userInfo.value {
                            userInfo.name = name
                            
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        // continue without displaying an error message
                        return Driver.just(())
                        
                    case .sessionTimeOut:
                        return useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                        
                    case .authenticationError:
                        // navigate to the forced logout screen without displaying an error message
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
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
        
        let userAction = start
            .withLatestFrom(self.useCase.hasLoggedin().asDriverOnErrorJustComplete())
            .filter({ $0 })
            .withLatestFrom(AppManager.shared.userInfo.asDriver())
            .map({ userInfo -> String in
                guard let userInfo = userInfo else {
                    return ""
                }
                
                return userInfo.name
            })
            .do(onNext: { _ in
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let check = Driver.merge(userAction.mapToVoid(), retryAction)
            .withLatestFrom(userAction)
            .flatMapFirst({ name -> Driver<String> in
                if name.isEmpty {
                    return useCase.getUserName()
                        .catchError({ (error) -> Observable<String> in
                            if let error = error as? GooServiceError {
                                switch error {
                                case .maintenanceCannotUpdate(let data):
                                    if let name = data as? String {
                                        return Observable.just(name)
                                    }
                                    
                                default:
                                    break
                                }
                            }
                            
                            return Observable.error(error)
                        })
                        .trackError(userNameErrorTracker)
                        .asDriverOnErrorJustComplete()
                }
                
                return Driver.just(name)
            })
            .flatMapFirst({ (name) -> Driver<Void> in
                return useCase.getLinkedDevices()
                    .catchError({ (error) -> Observable<[DeviceInfo]> in
                        if let error = error as? GooServiceError {
                            switch error {
                            case .maintenanceCannotUpdate(let data):
                                if let list = data as? [DeviceInfo] {
                                    checkListDevice.onNext(true)
                                    eventListDevice.onNext(list)
                                    return Observable.just(list)
                                } else {
                                    return Observable.just([])
                                }
                            case .maintenance:
                                return Observable.just([])
                            default:
                                break
                            }
                        }
                        
                        return Observable.error(error)
                    })
                    .trackError(deviceStatusErrorTracker)
                    .map({ list -> DeviceStatus in
                        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
                            return .unknown
                        }
                        checkListDevice.onNext(true)
                        eventListDevice.onNext(list)
                        return list.first(where: { $0.id == deviceID }) != nil ? .registered : .unregistered
                    })
                    .asDriver(onErrorJustReturn: .unknown)
                    .do(onNext: { status in
                        if var userInfo = AppManager.shared.userInfo.value {
                            userInfo.name = name
                            userInfo.deviceStatus = status
                            
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                    })
                    .mapToVoid()
            })

        return Driver.merge(check, userNameErrorHandler, deviceStatusErrorHandler)
    }
    
    private func showLoginFlow(tap: Driver<Void>,
                               startNewAction: PublishSubject<Void>,
                               cancelTrigger: Driver<Void>,
                               isValidatingServer: BehaviorRelay<Bool>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                isValidatingServer.accept(false)
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Menu.Error.Login.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate:
                        return self.navigator
                            .showConfirmMessage(L10n.Menu.Error.Login.maintenanceCannotUpdate)
                            .filter({ $0 })
                            .asDriverOnErrorJustComplete()
                            .mapToVoid()
                            .do(onNext: self.navigator.toLoginScreen)
                        
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
        
        let opened = tap
            .withLatestFrom(activityIndicator)
            .filter({ $0 == false })
            .mapToVoid()
            .do(onNext: {
                startNewAction.onNext(())
            })
            .flatMapLatest({ self.useCase.hasLoggedin().asDriverOnErrorJustComplete() })
            .flatMap({ (isLoggedin) -> Driver<Void> in
                if isLoggedin {
                    isValidatingServer.accept(false)
                    return self.navigator.toLogoutConfirmation()
                        .takeUntil(cancelTrigger.asObservable())
                        .filter({ $0 })
                        .asDriverOnErrorJustComplete()
                        .flatMap({ _ in self.useCase.logout().asDriverOnErrorJustComplete().mapToVoid() })
                } else {
                    isValidatingServer.accept(true)
                    return self.useCase.checkAPIStatus()
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .takeUntil(cancelTrigger.asObservable())
                        .asDriverOnErrorJustComplete()
                        .do(onNext: {
                            isValidatingServer.accept(false)
                            self.navigator.toLoginScreen()
                        })
                }
            })
        
        return Driver.merge(opened, errorHandler)
    }
    
    private func showRegisterDevicesFlow(tap: Driver<Void>,
                                         startNewAction: PublishSubject<Void>,
                                         cancelTrigger: Driver<Void>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Menu.Error.RegisterDevice.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate:
                        return Driver.just(())
                            .do(onNext: self.navigator.toDevicesScreen)
                         
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
        
        let eventMoveDevices: PublishSubject<Void> = PublishSubject.init()
        let eventGetList: PublishSubject<DeviceInfo> = PublishSubject.init()
        let errorRemoveDevices = ErrorTracker()
        
        let opened = tap
            .withLatestFrom(activityIndicator)
            .filter({ $0 == false })
            .do(onNext: { _ in
                startNewAction.onNext(())
            })
            .flatMap({ _ in
                return self.useCase.checkAPIStatus()
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .takeUntil(cancelTrigger.asObservable())
                    .asDriverOnErrorJustComplete()
            })
            .flatMap{ _ in self.useCase.getBillingInfoStatus()
                .trackError(errorTracker)
                .takeUntil(cancelTrigger.asObservable())
                .asDriverOnErrorJustComplete() }
            .do(onNext: { (obj) in
                AppManager.shared.billingInfo.accept(obj)
                AppManager.shared.updateSettingSearch(billingStatus: obj)
            })
            .flatMap { _ in self.useCase.getLinkedDevices()
                .trackActivity(activityIndicator)
                .trackError(errorTracker)
                .takeUntil(cancelTrigger.asObservable())
                .asDriverOnErrorJustComplete() }
            .map { list -> Void in

                let billingStatus = AppManager.shared.billingInfo.value.billingStatus

                if (list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) != nil) && billingStatus == .free {
                    if let index = list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) {
                        eventGetList.onNext(list[index])
                    } else {
                        eventMoveDevices.onNext(())
                    }
                } else {
                    eventMoveDevices.onNext(())
                }

                return ()
            }

        let doEventMoveDevices = Observable.merge(eventMoveDevices.asObservable(), errorRemoveDevices.mapToVoid().asObservable())
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: navigator.toDevicesScreen )
            .asDriverOnErrorJustComplete()

        let doEventGetList = eventGetList
            .flatMap{ self.useCase.deleteDevice(device: $0).trackError(errorRemoveDevices).takeUntil(cancelTrigger.asObservable()) }
            .flatMap { _ -> Driver<[DeviceInfo]> in
                return self.useCase.getLinkedDevices()
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .takeUntil(cancelTrigger.asObservable())
                    .asDriverOnErrorJustComplete()
            }
            .map { list -> Void in
                let billingStatus = AppManager.shared.billingInfo.value.billingStatus

                if (list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) != nil) && billingStatus == .free {
                    if let index = list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }) {
                        eventGetList.onNext(list[index])
                    } else {
                        eventMoveDevices.onNext(())
                    }
                } else {
                    eventMoveDevices.onNext(())
                }
                return ()
            }
            .asDriverOnErrorJustComplete()
            
        
        return Driver.merge(opened, errorHandler, doEventMoveDevices, doEventGetList)
    }
}
