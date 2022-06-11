//
//  BackupListUseCase.swift
//  GooDic
//
//  Created by Vinh Nguyen on 25/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol BackupListUseCaseProtocol: AuthenticationUseCaseProtocol {
    func fetchBackupDraftList(document: Document) -> Observable<[CloudBackupDocument]>
    func fetchBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument) -> Observable<CloudBackupDocument>
}

struct BackupListUseCase: BackupListUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    
    func fetchBackupDraftList(document: Document) -> Observable<[CloudBackupDocument]> {
        return cloudService.gateway
            .getBackupDraftList(document: document)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({
                return $0
            })
    }
    
    func fetchBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument) -> Observable<CloudBackupDocument> {
        return cloudService.gateway
            .getBackupDraftDetail(document: document, backupDocument: backupDocument)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({
                return $0
            })
    }
}
