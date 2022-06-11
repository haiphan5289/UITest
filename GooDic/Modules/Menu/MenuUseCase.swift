//
//  MenuUseCase.swift
//  GooDic
//
//  Created by ttvu on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import GooidSDK

protocol MenuUseCaseProtocol: AuthenticationUseCaseProtocol, CheckAPIFeature {
    func getUserName() -> Observable<String>
    func getLinkedDevices() -> Observable<[DeviceInfo]>
    func getBillingInfoStatus() -> Observable<BillingInfo>
    func deleteDevice(device: DeviceInfo) -> Observable<Void>
}

struct MenuUseCase: MenuUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
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
    
    func getUserName() -> Observable<String> {
        cloudService.gateway
            .getAccountInfo()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func getLinkedDevices() -> Observable<[DeviceInfo]> {
        cloudService.gateway
            .getRegisteredDevices()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
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
