//
//  CloudDraftsUseCase.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol CloudDraftsUseCaseProtocol: AuthenticationUseCaseProtocol {
    func fetchDrafts(query: CloudDraftQuery, offset: Int, limit: Int, sort: SortModel) -> Observable<PagingInfo<Document>>
    func fetchDraftDetail(draft: Document) -> Observable<Document>
    func fetchDraftsDetail(drafts: [Document]) -> Observable<[Document]>
    func saveToTrash(drafts: [Document]) -> Observable<Void>
    func delete(documents: [Document]) -> Observable<Void>
    
    func showSwipeActionInDocument() -> Bool
    func learnedSwipeDocumentTooltip() -> Observable<Void>
    func updateFolder(folder: Folder) -> Observable<Void>
    func isNewUser() -> Bool
    func getDraftSettings(settingKey: String, folderId: String) -> Observable<String>
    func sortDrafts(drafts: [Document], sortedAt: String, folderId: String) -> Observable<Void>
}

struct CloudDraftsUseCase: CloudDraftsUseCaseProtocol {
    
    @GooInject var cloudService: CloudService
    @GooInject var dbService: DatabaseService
    
    func sortDrafts(drafts: [Document], sortedAt: String, folderId: String) -> Observable<Void> {
        return cloudService.gateway
            .sortDrafts(drafts: drafts, sortedAt: sortedAt, folderId: folderId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func getDraftSettings(settingKey: String, folderId: String) -> Observable<String> {
        return cloudService.gateway
            .getDraftSettings(settingKey: settingKey, folderId: folderId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
    }
    
    
    func fetchDrafts(query: CloudDraftQuery, offset: Int, limit: Int, sort: SortModel) -> Observable<PagingInfo<Document>> {
        return cloudService.gateway
            .getDraftList(query: query, offset: offset, limit: limit, sort: sort)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({
                PagingInfo(offset: $0.offset,
                           limit: $0.limit,
                           totalItems: $0.totalItems,
                           hasMorePages: $0.hasMorePages,
                           items: $0.items.map({ $0.document }),
                           name: $0.name,
                           sortedAt: $0.sortedAt)
            })
    }
    
    func updateFolder(folder: Folder) -> Observable<Void> {
        return dbService.gateway.update(folder: folder)
    }
    
    func fetchDraftDetail(draft: Document) -> Observable<Document> {
        guard let cloudDraft = CloudDocument(document: draft) else {
            return Observable.error(NSError())
        }
        
        return cloudService.gateway
            .getDraftDetail(cloudDraft)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .map({ $0.document })
    }
    
    func fetchDraftsDetail(drafts: [Document]) -> Observable<[Document]> {
        let collection = drafts
            .map({ CloudDocument(document: $0) })
            .compactMap({ $0 })
            .map({
                cloudService.gateway
                    .getDraftDetail($0)
                    .map({ $0.document })
            })
        
        return Observable
            .zip(collection)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func saveToTrash(drafts: [Document]) -> Observable<Void> {
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
    
    func delete(documents: [Document]) -> Observable<Void> {
        let draftIds = documents.map({ $0.id })
        
        return cloudService.gateway
            .deleteDrafts(draftIds: draftIds)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func showSwipeActionInDocument() -> Bool {
        return AppSettings.guideUserToSwipeDraft == false
    }
    
    func learnedSwipeDocumentTooltip() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            AppSettings.guideUserToSwipeDraft = true
            
            observer.onNext(())
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func isNewUser() -> Bool {
        let currentBuildVersion = Int(Bundle.main.applicationBuild) ?? 0
        
        if AppSettings.firstInstallBuildVersion == -1 {
            return false
        }
        
        return AppSettings.firstInstallBuildVersion == currentBuildVersion
    }
}
