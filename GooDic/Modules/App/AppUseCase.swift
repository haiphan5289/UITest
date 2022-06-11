//
//  AppUseCase.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import GooidSDK

protocol AppUseCaseProtocol: AuthenticationUseCaseProtocol {
    
    func checkVersionAgreement(isHighPriority: Bool) -> Observable<Date?>
    func isNewVersion(date: Date) -> Bool
    func isFirstRun() -> Bool
    func isFirstLogin() -> Bool
    func isForceLogout() -> Bool
    func getBillingInfoStatus() -> Observable<BillingInfo>
    func getListDevice(errTrack: ErrorTracker) -> Observable<[DeviceInfo]>
    func detectUserExist() -> Bool
    func getUIBillingTextValue() -> Observable<FileStoreBillingText?>
    func getDataForceUpdate() -> Observable<FileStoreForceUpdate?>
}

struct AppUseCase: AppUseCaseProtocol {
    
    @GooInject var remoteConfigService: RemoteConfigService
    @GooInject var cloudService: CloudService
    
    func checkVersionAgreement(isHighPriority: Bool) -> Observable<Date?> {
        let dateRequest = remoteConfigService.gateway
            .agreementDate()
        
        if isHighPriority {
            return dateRequest.retry(3)
        }
        
        return dateRequest
    }
    
    func isNewVersion(date: Date) -> Bool {
        return AppSettings.agreementDate.timeIntervalSince(date) < 0
    }
    
    func isFirstRun() -> Bool {
        return AppSettings.firstRun
    }
    
    func isFirstLogin() -> Bool {
        return AppSettings.firstLogin
    }
    
    func isForceLogout() -> Bool {
        return AppSettings.forceLogout
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
    
    func getListDevice(errTrack: ErrorTracker) -> Observable<[DeviceInfo]> {
        AppManager.shared.detectListDeviceWeb(errTrack: errTrack)
        return AppManager.shared.detectFinalListDevice.asObservable()
    }
    
    func detectUserExist() -> Bool {
        let cookie = GooidSDK.sharedInstance.generateCookies()
        return (cookie?.count ?? 0 > 0 ) ? true : false
    }
    
    func getUIBillingTextValue() -> Observable<FileStoreBillingText?> {
        return remoteConfigService.gateway.getUIBillingTextValue()
    }
    
    func getDataForceUpdate() -> Observable<FileStoreForceUpdate?> {
        return remoteConfigService.gateway.getDataforceUpdate()
    }
}
