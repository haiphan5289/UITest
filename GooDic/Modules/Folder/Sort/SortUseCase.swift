//
//  SortUseCase.swift
//  GooDic
//
//  Created by haiphan on 09/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol SortUseCaseProtocol: AuthenticationUseCaseProtocol {
    func getWebSettings(settingKey: String) -> Observable<String>
    func postWebSetiings(sortMode: SortModel, settingKey: String) -> Observable<Void>
    func getDraftSettings(settingKey: String, folderId: String) -> Observable<String>
    func postDraftSetiings(sortMode: SortModel, settingKey: String, folderId: String) -> Observable<Void>
    func getBillingInfo() -> Observable<BillingInfo>
}

struct SortUseCase: SortUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
    func getBillingInfo() -> Observable<BillingInfo> {
        return AppManager.shared.billingInfo.asObservable()
    }
    
    func postDraftSetiings(sortMode: SortModel, settingKey: String, folderId: String) -> Observable<Void> {
        return cloudService.gateway
            .postDraftSetiings(sortMode: sortMode, settingKey: settingKey, folderId: folderId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    func getDraftSettings(settingKey: String, folderId: String) -> Observable<String> {
        return cloudService.gateway
            .getDraftSettings(settingKey: settingKey, folderId: folderId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    func postWebSetiings(sortMode: SortModel, settingKey: String) -> Observable<Void> {
        return cloudService.gateway
            .postWebSetiings(sortMode: sortMode, settingKey: settingKey)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    func getWebSettings(settingKey: String) -> Observable<String> {
        return cloudService.gateway
            .getWebSettings(settingKey: settingKey)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
}
