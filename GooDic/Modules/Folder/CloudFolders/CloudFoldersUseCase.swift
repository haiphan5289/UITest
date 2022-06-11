//
//  CloudFoldersUseCase.swift
//  GooDic
//
//  Created by ttvu on 1/15/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol CloudFoldersUseCaseProtocol: AuthenticationUseCaseProtocol {
    func fetchCloudFolders(offset: Int, limit: Int, sortMode: SortModel?) -> Observable<PagingInfo<Folder>>
    func numberOfDrafts(in folderId: String) -> Observable<Int>
    
    func deleteCloudFolder(folderId: String) -> Observable<Void>
    func fetchDrafts(inCloudfolder cloudFolderId: String, totalItems: Int) -> Observable<[Document]>
    func saveToTrash(drafts: [Document]) -> Observable<Void>
    func getWebSettings(settingKey: String) -> Observable<String>
    func sortFolders(folders: [Folder], sortedAt: String) -> Observable<Void>
}

struct CloudFoldersUseCase: CloudFoldersUseCaseProtocol {
    @GooInject var dbService: DatabaseService
    @GooInject var cloudService: CloudService
    
    func getWebSettings(settingKey: String) -> Observable<String> {
        return cloudService.gateway
            .getWebSettings(settingKey: settingKey)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    func sortFolders(folders: [Folder], sortedAt: String) -> Observable<Void> {
        return cloudService.gateway
            .sortFolders(folders: folders, sortedAt: sortedAt)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func fetchCloudFolders(offset: Int, limit: Int, sortMode: SortModel?) -> Observable<PagingInfo<Folder>> {
        return cloudService.gateway
            .getFolderList(offset: offset, limit: limit, sortMode: sortMode)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({
                PagingInfo(offset: $0.offset,
                           limit: $0.limit,
                           totalItems: $0.totalItems,
                           hasMorePages: $0.hasMorePages,
                           items: $0.items.map({ $0.folder }),
                           name: $0.name,
                           sortedAt: $0.sortedAt)
            })
    }
    
    func numberOfDrafts(in folderId: String) -> Observable<Int> {
        let query: CloudDraftQuery = folderId.isEmpty ? .uncategoried : .folderId(folderId)
        return cloudService.gateway
            .getDraftList(query: query, offset: 0, limit: 1, sort: SortModel.valueDefaultDraft)
            .map({ $0.totalItems })
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func deleteCloudFolder(folderId: String) -> Observable<Void> {
        return cloudService.gateway
            .deleteFolder(folderId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func fetchDrafts(inCloudfolder cloudFolderId: String, totalItems: Int) -> Observable<[Document]> {
        let query: CloudDraftQuery = cloudFolderId.isEmpty ? .uncategoried : .folderId(cloudFolderId)
        let totalRequest = Int((Float(totalItems) / Float(GlobalConstant.maxItemPerPage)).rounded(.up))
        
        if totalRequest == 0 {
            return Observable.just([])
        }
        
        let collection = (0..<totalRequest)
            .map({
                cloudService.gateway
                    .getDraftList(query: query, offset: $0 * GlobalConstant.maxItemPerPage, limit: GlobalConstant.maxItemPerPage, sort: SortModel.valueDefaultDraft)
                    .flatMap({ paging -> Observable<[Document]> in
                        let list = paging.items.map({
                            self.cloudService.gateway
                                .getDraftDetail($0)
                                .map({ $0.document })
                        })
                        
                        return Observable.zip(list)
                    })
            })
        
        return Observable.zip(collection)
            .map({ $0.flatMap { $0 } })
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func saveToTrash(drafts: [Document]) -> Observable<Void> {
        if drafts.isEmpty {
            return Observable.just(())
        }
        
        let collection = drafts
            .map({ (draft) -> Document in
                var newDraft = draft.duplicate()
                newDraft.status = .deleted
                return newDraft
            })
            .map({ dbService.gateway.update(document: $0, updateDate: true) })
        
        return Observable
            .zip(collection)
            .mapToVoid()
    }
}
