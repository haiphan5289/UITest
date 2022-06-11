//
//  LocalFolderSelectionUseCase.swift
//  GooDic
//
//  Created by ttvu on 1/15/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

protocol LocalFolderSelectionUseCaseProtocol: AuthenticationUseCaseProtocol {
    var fetchedResultsController: NSFetchedResultsController<CDFolder> { get }
    func move(localDrafts: [Document], toLocalFolderId folderId: String) -> Observable<Void>
    func fetchDetail(cloudDrafts: [Document]) -> Observable<[Document]>
    func save(cloudDrafts: [Document], toLocalFolderId folderId: String) -> Observable<Void>
    func delete(cloudDrafts: [Document]) -> Observable<Void>
    var getDocsCloud: PublishSubject<[Document]> { get }
}

struct LocalFolderSelectionUseCase: LocalFolderSelectionUseCaseProtocol {
    
    
    @GooInject var dbService: DatabaseService
    @GooInject var cloudService: CloudService
    var fetchedResultsController: NSFetchedResultsController<CDFolder>
    var getDocsCloudOb: PublishSubject<[Document]> = PublishSubject.init()
    
    init() {
        let sort = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchedResultsController = createFetchedResultsController(sorts: [sort], predicate: nil)
    }
    
    var getDocsCloud: PublishSubject<[Document]> {
        return self.getDocsCloudOb
    }
    
    func move(localDrafts: [Document], toLocalFolderId folderId: String) -> Observable<Void> {
        let collection = localDrafts
            .map({ dbService.gateway.move(document: $0, to: folderId) })
        
        return Observable
            .zip(collection)
            .mapToVoid()
    }
    
    func fetchDetail(cloudDrafts: [Document]) -> Observable<[Document]> {
        enum Result {
            case normal(Document)
            case error(Error)
        }
        
        let collection = cloudDrafts
            .map({ CloudDocument(document:$0) })
            .compactMap({ $0 })
            .map({ cloudService.gateway
                .getDraftDetail($0)
                .map({ Result.normal($0.document) })
                .catchError({ error -> Observable<Result> in
                    return Observable.just(Result.error(error))
                })
                .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
                .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            })
        
        return Observable
            .zip(collection)
            .flatMap({ (list) -> Observable<[Document]> in
                var drafts: [Document] = []
                var isMaintenanceCannotUpdate = false
                
                for item in list {
                    switch item {
                    case .normal(let draft):
                        drafts.append(draft)
                    case .error(let error):
                        if let error = error as? GooServiceError {
                            switch error {
                            case .maintenanceCannotUpdate(let data):
                                if let doc = data as? CloudDocument {
                                    isMaintenanceCannotUpdate = true
                                    drafts.append(doc.document)
                                    continue
                                }
                            default:
                                break
                            }
                        }
                        
                        return Observable.error(error)
                    }
                }
                
                if isMaintenanceCannotUpdate {
                    return Observable.error(GooServiceError.maintenanceCannotUpdate(drafts))
                }
                
                return Observable.just(drafts)
            })
    }

    func save(cloudDrafts: [Document], toLocalFolderId folderId: String) -> Observable<Void> {
        var docs: [Document] = []
        let collection = cloudDrafts
            .map({ document -> Observable<Void> in
                var newDocument = document.duplicate()
                newDocument.folderId = FolderId.local(folderId)
                docs.append(newDocument)
                return dbService.gateway.create(document: newDocument)
            })
        self.getDocsCloudOb.onNext(docs)
        return Observable
            .zip(collection)
            .mapToVoid()
    }
    
    func delete(cloudDrafts: [Document]) -> Observable<Void> {
        let draftIds = cloudDrafts.map({ $0.id })
        
        return cloudService.gateway
            .deleteDrafts(draftIds: draftIds)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
}
