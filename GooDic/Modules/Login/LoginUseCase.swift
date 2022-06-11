//
//  LoginUseCase.swift
//  GooDic
//
//  Created by paxcreation on 11/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import GooidSDK
import RxCocoa

typealias ValidateServer = (Bool)
protocol LoginUseCaseProtocol: AuthenticationUseCaseProtocol {
    var statusServer: PublishSubject<Void> { get set }
    var statusServerError: PublishSubject<GooServiceError> { get set }
    var erroNetwork: PublishSubject<Error> { get set }
    var activityIndicator: ActivityIndicator { get set }
    func login(waitingAPIListDevice: BehaviorRelay<Bool>?) -> Observable<GooIDResult>
    func register() -> Observable<GooIDResult>
    func loggined()
    func validateServer()
    func getListDevice() -> Observable<[DeviceInfo]>
    func getBillingInfoStatus() -> Observable<BillingInfo>
    func deleteDevice(device: DeviceInfo) -> Observable<Void>
    func sendAFEventLoginSuccess()
}

struct LoginUseCase: LoginUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
    var erroNetwork: PublishSubject<Error> = PublishSubject.init()
    var statusServerError: PublishSubject<GooServiceError> = PublishSubject.init()
    var activityIndicator: ActivityIndicator = ActivityIndicator()
    var statusServer: PublishSubject<Void> = PublishSubject.init()
    private let disposeBag = DisposeBag()
    
    func deleteDevice(device: DeviceInfo) -> Observable<Void> {
        return cloudService.gateway
            .deleteDevice(deviceId: device.id)
            .do(onNext: {
                if let currentDeviceId = UIDevice.current.identifierForVendor?.uuidString, currentDeviceId == device.id {
                    var userInfo = AppManager.shared.userInfo.value
                    userInfo?.deviceStatus = .unregistered
                    AppManager.shared.userInfo.accept(userInfo)
                }
            })
    }
    
    func validateServer() {
        cloudService.gateway.getAPIStatus()
            .retry(GlobalConstant.requestRetry)
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
    
    func getListDevice() -> Observable<[DeviceInfo]> {
        return cloudService.gateway
            .getRegisteredDevices()
            .catchError({ (error) -> Observable<[DeviceInfo]> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenanceCannotUpdate(_):
                        return Observable.just([])
                    case .maintenance:
                        return Observable.just([])
                    default:
                        break
                    }
                }
                
                return Observable.error(error)
            })
            .trackActivity(activityIndicator)
    }
    
    func login(waitingAPIListDevice: BehaviorRelay<Bool>?) -> Observable<GooIDResult> {
        return GooidSDK.sharedInstance.rx.login(waitingAPIListDevice: waitingAPIListDevice)
    }
    
    func register() -> Observable<GooIDResult> {
        return GooidSDK.sharedInstance.rx.register()
    }
    
    func loggined() {
        AppSettings.firstLogin = false
    }
    
    func sendAFEventLoginSuccess() {
        GATracking.sendAFEventLoginSuccess()
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

