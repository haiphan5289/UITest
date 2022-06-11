//
//  RegisterDeviceUseCase.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//
import Foundation
import RxSwift
import GooidSDK

protocol RegisterDeviceUseCaseProtocol: AuthenticationUseCaseProtocol {
    var trackActivity: ActivityIndicator { get set }
    func getListDevice() -> Observable<[DeviceInfo]>
    func deleteDevice(device: DeviceInfo) -> Observable<Void>
    func addDevice(name: String) -> Observable<Void>
    func getBillingInfoStatus() -> Observable<BillingInfo>
}

struct RegisterDeviceUseCase: RegisterDeviceUseCaseProtocol {
    var trackActivity: ActivityIndicator = ActivityIndicator()
    
    @GooInject var cloudService: CloudService
    
    func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    func getNameDevice() -> Observable<String> {
        let deviceModel = self.modelIdentifier()
        
        return cloudService.gateway
            .getDeviceName(deviceCode: deviceModel)
            .trackActivity(self.trackActivity)
    }
    
    func getListDevice() -> Observable<[DeviceInfo]> {
        return cloudService.gateway
            .getRegisteredDevices()
            .trackActivity(self.trackActivity)
    }
    
    func deleteDevice(device: DeviceInfo) -> Observable<Void> {
        return cloudService.gateway
            .deleteDevice(deviceId: device.id)
            .trackActivity(self.trackActivity)
            .do(onNext: {
                if let currentDeviceId = UIDevice.current.identifierForVendor?.uuidString, currentDeviceId == device.id {
                    var userInfo = AppManager.shared.userInfo.value
                    userInfo?.deviceStatus = .unregistered
                    AppManager.shared.userInfo.accept(userInfo)
                }
            })
    }
    
    func addDevice(name: String) -> Observable<Void> {
        return cloudService.gateway
            .addDevice(name: name)
            .trackActivity(self.trackActivity)
            .do(onNext: {
                var userInfo = AppManager.shared.userInfo.value
                userInfo?.deviceStatus = .registered
                AppManager.shared.userInfo.accept(userInfo)
            })
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


