//
//  RemoteConfigService.swift
//  GooDic
//
//  Created by ttvu on 6/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public protocol RemoteConfigGatewayProtocol {
    func agreementDate() -> Observable<Date?>
    func notifyWebview() -> Observable<NotiWebModel?>
    func titleForBanner() -> Observable<NotificationBannerHome?>
    func notifyDictionary() -> Observable<NotiWebModel?>
    func getUIBillingTextValue() -> Observable<FileStoreBillingText?>
    func getDataforceUpdate() -> Observable<FileStoreForceUpdate?>
}

public typealias RemoteConfigService = GooService<RemoteConfigGatewayProtocol>
