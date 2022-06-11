//
//  LocalDraftsUseCase.swift
//  GooDic
//
//  Created by ttvu on 12/16/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import CoreData

protocol LocalDraftsUseCaseProtocol {
    var fetchedResultsController: NSFetchedResultsController<CDDocument> { get }
    func bin(documents: [Document]) -> Observable<Void>
    
    func showSwipeActionInDocument() -> Bool
    func learnedSwipeDocumentTooltip() -> Observable<Void>
    
    func deleteEmptyDocuments() -> Observable<Void>
    func isNewUser() -> Bool
    func requestValue(sortModel: SortModel?)
    func updateFolder(folder: Folder) -> Observable<Void>
    func updateSortFolder(folder: Folder)
    func updateDocument(drafts: [Document])
}

struct LocalDraftsUseCase: LocalDraftsUseCaseProtocol {
    
    @GooInject var dbService: DatabaseService
    
    var fetchedResultsController: NSFetchedResultsController<CDDocument>
    var request: NSFetchRequest<CDDocument>!
    private let entityName = String(describing: CDDocument.self)
    private var predicate: NSPredicate?
    private var query: FolderId = .none
    
    init(query: FolderId = .none, folder: Folder? = nil) {
        self.query = query
        self.request = NSFetchRequest(entityName: entityName)
        self.request.sortDescriptors = []
        self.request.fetchBatchSize = 20
        self.request.returnsObjectsAsFaults = false
        switch query {
        case .none:
            
            self.predicate = NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue)
            fetchedResultsController = createFetchedResultsControllerDraft(request: self.request)
            self.requestValue(sortModel: nil)
        case let .local(id):
            if id.isEmpty {
                self.predicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue), NSPredicate(format: "folders.@count == 0")])
                
                fetchedResultsController = createFetchedResultsControllerDraft(request: self.request)
                self.requestValue(sortModel: AppSettings.sortModelDraftsUncategorized)
            } else {
                self.predicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue), NSPredicate(format: "SUBQUERY(folders, $folder, $folder.id == %@).@count > 0", id)])
                fetchedResultsController = createFetchedResultsControllerDraft(request: self.request)
                
                if let folder = folder {
                    self.requestValue(sortModel: folder.getSortModel())
                }
            }

        case .cloud(_):
            assertionFailure("a cloudId can't use to get data at local")
            fetchedResultsController = NSFetchedResultsController<CDDocument>()
            break
        }
        
    }
    
    func updateDocument(drafts: [Document]) {
        if drafts.isEmpty {
            return
        }
        _ = drafts.map({ dbService.gateway.updateDocs(document: $0, updateDate: false) })
    }
    
    func updateSortFolder(folder: Folder)  {
        dbService.gateway.updateSort(folder: folder)
    }
    
    func updateFolder(folder: Folder) -> Observable<Void> {
        return dbService.gateway.update(folder: folder)
    }

    func sortRequest(query: FolderId = .none, sortModel: SortModel?) -> NSSortDescriptor? {
        var sort: NSSortDescriptor!
        
        switch query {
        case .none:
            switch AppSettings.sortModelDrafts.sortName {
            case .free: break
            case .manual:
                sort = NSSortDescriptor(key: "manualIndex", ascending: false)
            case .updated_at:
                sort = NSSortDescriptor(key: "updatedAt", ascending: AppSettings.sortModelDrafts.asc)
            case .created_at:
                sort = NSSortDescriptor(key: "createdAt", ascending: AppSettings.sortModelDrafts.asc)
            case .title:
                sort = NSSortDescriptor(key: "title", ascending: AppSettings.sortModelDrafts.asc)
            }
            return sort
        case .local:
            guard let sortModel = sortModel else {
                return nil
            }
            switch sortModel.sortName {
            case .free: break
            case .manual:
                sort = NSSortDescriptor(key: "manualIndex", ascending: false)
            case .updated_at:
                sort = NSSortDescriptor(key: "updatedAt", ascending: sortModel.asc)
            case .created_at:
                sort = NSSortDescriptor(key: "createdAt", ascending: sortModel.asc)
            case .title:
                sort = NSSortDescriptor(key: "title", ascending: sortModel.asc)
            }
            return sort
            
        default: return nil
        }
    }
    
    func requestValue(sortModel: SortModel?) {
        self.request.predicate = predicate
        if let sort = self.sortRequest(query: self.query, sortModel: sortModel) {
            request.sortDescriptors = [sort]
        } else {
            request.sortDescriptors = []
        }
        
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = false
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print("Fetch failed")
        }
    }
    
    mutating func getFetchedResultsController() -> NSFetchedResultsController<CDDocument> {
        return fetchedResultsController
    }
    
    func bin(documents: [Document]) -> Observable<Void> {
        let collection = documents.map({ dbService.gateway.bin(document: $0) })
        
        return Observable
            .zip(collection)
            .mapToVoid()
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
    
    func deleteEmptyDocuments() -> Observable<Void> {
        guard let list = fetchedResultsController.fetchedObjects else { return Observable.empty() }
        
        let emptyDataList = list.filter { (doc) -> Bool in
            let content = (doc.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (doc.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return title.isEmpty && content.isEmpty
        }
        
        return dbService.gateway.delete(documents: emptyDataList.map({ $0.document }))
    }
    
    func isNewUser() -> Bool {
        let currentBuildVersion = Int(Bundle.main.applicationBuild) ?? 0
    
        if AppSettings.firstInstallBuildVersion == -1 {
            return false
        }
        
        return AppSettings.firstInstallBuildVersion == currentBuildVersion
    }
}

