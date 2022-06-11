//
//  BackupDetailUseCase.swift
//  GooDic
//
//  Created by Vinh Nguyen on 26/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol BackupDetailUseCaseProtocol: AuthenticationUseCaseProtocol {
    func getBillingInfo() -> Observable<BillingInfo>
    func backupDraftRestore(document: Document, backupDocument: CloudBackupDocument) -> Observable<Void>
}

struct BackupDetailUseCase: BackupDetailUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
    func getBillingInfo() -> Observable<BillingInfo> {
        return AppManager.shared.billingInfo.asObservable()
    }
    
    func backupDraftRestore(document: Document, backupDocument: CloudBackupDocument) -> Observable<Void> {
        return cloudService.gateway
            .backupDraftRestore(document: document, backupDocument: backupDocument)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
}
