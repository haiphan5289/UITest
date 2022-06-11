//
//  RemoteConfigLocalGateway.swift
//  GooDic
//
//  Created by ttvu on 6/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public struct RemoteConfigLocalGateway: RemoteConfigGatewayProtocol {
    public func notifyDictionary() -> Observable<NotiWebModel?> {
        return Observable.just(nil)
    }
    
    public func agreementDate() -> Observable<Date?> {
        return Observable.just(Date())
    }
    
    public func notifyWebview() -> Observable<NotiWebModel?> {
        return Observable.just(nil)
    }
    
    public func titleForBanner() -> Observable<NotificationBannerHome?> {
        return Observable.just(nil)
    }
    
    public func getUIBillingTextValue() -> Observable<FileStoreBillingText?> {
        return Observable.just(nil)
    }
    
    public func getDataforceUpdate() -> Observable<FileStoreForceUpdate?> {
        return Observable.just(nil)
    }
}
