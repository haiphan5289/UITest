//
//  CloudFolderSelectionUserCase.swift
//  GooDic
//
//  Created by ttvu on 1/15/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol CloudFolderSelectionUserCaseProtocol: AuthenticationUseCaseProtocol {
    func fetchCloudFolders(offset: Int, limit: Int) -> Observable<PagingInfo<Folder>>
    func move(cloudDrafts: [Document], toCloudFolderId folderId: String) -> Observable<Void>
    func move(localDrafts: [Document], toCloudFolderId folderId: String) -> Observable<Void>
    
    func delete(localDrafts: [Document]) -> Observable<Void>
}

struct CloudFolderSelectionUserCase: CloudFolderSelectionUserCaseProtocol {
    @GooInject var dbService: DatabaseService
    @GooInject var cloudService: CloudService
    
    func fetchCloudFolders(offset: Int, limit: Int) -> Observable<PagingInfo<Folder>> {
        return cloudService.gateway
            .getFolderList(offset: offset, limit: limit, sortMode: nil)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({
                PagingInfo(offset: $0.offset,
                           limit: $0.limit,
                           totalItems: $0.totalItems,
                           hasMorePages: $0.hasMorePages,
                           items: $0.items.map({ $0.folder }),
                           name: $0.name)
            })
    }
    
    func move(cloudDrafts: [Document], toCloudFolderId folderId: String) -> Observable<Void> {
        let draftIds = cloudDrafts.map({ $0.id })
        
        return cloudService.gateway
            .moveDrafts(draftIds: draftIds, to: folderId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .mapToVoid()
    }
    
    func move(localDrafts: [Document], toCloudFolderId folderId: String) -> Observable<Void> {
        let collection = localDrafts
            .map({ $0.duplicate() })
            .map({ (document) -> CloudDocument in
                return CloudDocument(id: document.id,
                                     title: document.title,
                                     content: document.content,
                                     updatedAt: document.updatedAt,
                                     folderId: folderId,
                                     folderName: document.folderName,
                                     cursorPosition: document.cursorPosition,
                                     manualIndex: document.manualIndex)
            })
            .map({ cloudService.gateway.addDraft($0) })
        
        return Observable
            .zip(collection)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .mapToVoid()
    }
    
    func delete(localDrafts: [Document]) -> Observable<Void> {
        return dbService.gateway.delete(documents: localDrafts)
    }
}
