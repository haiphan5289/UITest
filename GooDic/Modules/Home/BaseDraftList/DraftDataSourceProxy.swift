//
//  DraftDataSourceProxy.swift
//  GooDic
//
//  Created by haiphan on 21/02/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

class DraftDataSourceProxy: NSObject {
    
    enum ExtendedCell {
        case addFolder
        case uncategorizedFolder
    }
    
    var drafts: [CDDocument] = []
    var rawDrafts: [CDDocument] = []
    let fetchedResultsController: NSFetchedResultsController<CDDocument>
    var folder: Folder?
    var sortModel: SortModel = SortModel.valueDefaultDraft
    let saveIndexFolderId: PublishSubject<Void> = PublishSubject.init()
    var folderId: FolderId?
    let reloadData: PublishSubject<Void> = PublishSubject.init()
//    let documentsEvent: BehaviorSubject<[Document]> = BehaviorSubject.init(value: [])
//    let documentsMovetoUncateEvent: BehaviorSubject<[Document]> = BehaviorSubject.init(value: [])
    
    init(fetchedResultsController: NSFetchedResultsController<CDDocument>, folder: Folder? = nil, folderId: FolderId = .none) {
        self.fetchedResultsController = fetchedResultsController
        self.folderId = folderId
        switch folderId {
        case .none:
            self.sortModel = AppSettings.sortModelDrafts
        case .local(let id):
            if let folder = folder, !id.isEmpty {
                self.folder = folder
                self.sortModel = folder.getSortModel()
            } else {
                self.sortModel = AppSettings.sortModelDraftsUncategorized
            }
        case .cloud: break
        }
        super.init()
    }
    
    func setResultsControllerDelegate(frcDelegate: NSFetchedResultsControllerDelegate) {
        self.fetchedResultsController.delegate = frcDelegate
        do {
            try self.fetchedResultsController.performFetch()
            self.updateFolders(sort: self.sortModel , isSave: false)
        } catch {
            print("Fetch failed")
        }
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        return self.drafts.count
    }
    
    func uiNewIndexPath(dataIndexPath: IndexPath?) -> IndexPath? {
        guard let dataIndexPath = dataIndexPath else { return nil }
        let cd = self.fetchedResultsController.object(at: dataIndexPath)
        if let index = self.drafts.firstIndex(where: { $0.id == cd.id }) {
            return IndexPath(row: index, section: 0)
        }
        return nil
    }
    
    func hasIndex(indexPath: IndexPath) -> Bool {
        if indexPath.row > self.drafts.count {
            return false
        }
        return true
    }
    
    func data(at indexPath: IndexPath) -> Document {
        self.drafts[indexPath.row].document
    }
    
    func checkManualIndex() {
        guard let folderId = self.folderId else {
            return
        }
        switch folderId {
        case .none:
            let list = AppSettings.draftManualIndex
            if list.count > 0 {
                list.enumerated().forEach { item in
                    let element = item.element
                    if (self.drafts.firstIndex(where: { $0.id == element.id }) == nil) {
                        if let index = AppSettings.draftManualIndex.firstIndex(where: { $0.id == element.id }) {
                            AppSettings.draftManualIndex.remove(at: index)
                        }
                        
                    }
                }
            }
        case .local(let id):
            if var f = self.folder, !id.isEmpty {
                self.drafts = self.fetchedResultsController.fetchedObjects ?? []
                self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
            } else if AppSettings.draftManualIndexUncategorized.count > 0 {
                let list = AppSettings.draftManualIndexUncategorized
                list.enumerated().forEach { item in
                    let element = item.element
                    if (self.drafts.firstIndex(where: { $0.id == element.id }) == nil) {
                        if let index = AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == element.id }) {
                            AppSettings.draftManualIndexUncategorized.remove(at: index)
                        }
                    }
                }
            }
        case .cloud: break
        }
    }
    
    func saveIndex() {
        guard let folder = self.folderId else {
            return
        }
        switch folder {
        case .none:
            AppSettings.draftManualIndex = []
            self.drafts.enumerated().forEach { item in
                let offset = item.offset
                let element = item.element
                let manualindex: FolderDataSourceProxy.ManualIndex = FolderDataSourceProxy.ManualIndex(id: element.id ?? "", index: offset)
                AppSettings.draftManualIndex.append(manualindex)
            }
            self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
        case .local(let id):
            if let folder = self.folder, !id.isEmpty {
                self.saveIndexFolderId.onNext(())
            } else {
                AppSettings.draftManualIndexUncategorized = []
                self.drafts.enumerated().forEach { item in
                    let offset = item.offset
                    let element = item.element
                    let manualindex: FolderDataSourceProxy.ManualIndex = FolderDataSourceProxy.ManualIndex(id: element.id ?? "", index: offset)
                    AppSettings.draftManualIndexUncategorized.append(manualindex)
                }
            }
            self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
            
        case .cloud: break
        }
    }
    
    func getIndexInsert() -> IndexPath? {
        return IndexPath(row: self.drafts.count, section: 0)
    }
    
    
    func getActionFetch(at oldIndexPath: inout IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: inout IndexPath?, sort: SortModel) {
        switch sort.sortName {
        case .manual:
            switch type {
            case .insert:
                self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
                if let indexPath = newIndexPath {
                    let idx: IndexPath = IndexPath(row: indexPath.row, section: 0)
                    let cd = self.fetchedResultsController.object(at: idx)
                    self.drafts.insert(cd, at: 0)
                    newIndexPath = IndexPath(row: 0, section: 0)
                    if let folder = self.folderId {
                        switch folder {
                        case .none:
                            if AppSettings.draftManualIndex.firstIndex(where: { $0.id == cd.id }) == nil {
                                AppSettings.draftManualIndex.insert(FolderDataSourceProxy.ManualIndex(id: cd.id ?? "", index: self.drafts.count), at: 0)
                            }
                            
                        case .local(let id):
                            if let folder = self.folder, !id.isEmpty {
                            } else if AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == cd.id }) == nil {
                                AppSettings.draftManualIndexUncategorized.insert(FolderDataSourceProxy.ManualIndex(id: cd.id ?? "", index: self.drafts.count), at: 0)
                            }
                        case .cloud: break
                        }
                    } else {
                        print("")
                    }
                    
                }
            case .delete:
                if let indexPath = oldIndexPath {
                    let idx: IndexPath = IndexPath(row: indexPath.row, section: 0)
                    if let indexFolder = self.drafts.firstIndex(where: { $0.id == self.rawDrafts[idx.row].id }) {
                        oldIndexPath = IndexPath(row: indexFolder, section: 0)
                        self.drafts.remove(at: indexFolder)
                        if let folder = self.folderId {
                            switch folder {
                            case .none:
                                if let index = AppSettings.draftManualIndex.firstIndex(where: { $0.id == self.rawDrafts[idx.row].id }) {
                                    AppSettings.draftManualIndex.remove(at: index)
                                }
                                
                            case .local(let id):
                                if let folder = self.folder, !id.isEmpty {
                                } else if let index = AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == self.rawDrafts[idx.row].id }) {
                                    AppSettings.draftManualIndexUncategorized.remove(at: index)
                                }
                            case .cloud: break
                            }
                        }
                        
                        self.rawDrafts.remove(at: idx.row)
                    }
                }
            case .update:
                if let indexPath = oldIndexPath {
                    let idx: IndexPath = IndexPath(row: indexPath.row, section: 0)
                    let cd = self.fetchedResultsController.object(at: idx)
                    if let indexFolder = self.drafts.firstIndex(where: { $0.id == cd.id }) {
                        oldIndexPath = IndexPath(row: indexFolder, section: 0)
                        self.drafts[indexFolder] = cd
                        if let folder = self.folderId {
                            switch folder {
                            case .none:
                                if let index = AppSettings.draftManualIndex.firstIndex(where: { $0.id == cd.id }) {
                                    AppSettings.draftManualIndex[index] = FolderDataSourceProxy.ManualIndex(id: cd.id ?? "", index: index)
                                }
                            case .local(let id):
                                if let folder = self.folder, !id.isEmpty {
                                } else if let index = AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == cd.id }) {
                                    AppSettings.draftManualIndexUncategorized[index] = FolderDataSourceProxy.ManualIndex(id: cd.id ?? "", index: index)
                                }
                            case .cloud: break
                            }
                        }

                    }
                }
            case .move: break
            @unknown default: break
            }
        case .created_at, .free, .title, .updated_at:
            self.sortModel = sort
            self.drafts = self.fetchedResultsController.fetchedObjects ?? []
            self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
            self.reloadData.onNext(())
        }
        
        //get list document latest
//        self.documentsEvent.onNext(self.drafts.map { $0.document })
    }
    
    func rearrange() {
        guard let folderId = self.folderId else {
            return
        }
        switch folderId {
        case .none:
            if AppSettings.draftManualIndex.count > 0 {
                AppSettings.draftManualIndex.enumerated().forEach { item in
                    let offset = item.offset
                    let element = item.element
                    if let index = self.drafts.firstIndex(where: { $0.id == element.id }) {
                        let folder = self.drafts[index]
                        self.drafts.remove(at: index)
                        if offset > self.drafts.count {
                            self.drafts.insert(folder, at: self.drafts.count)
                        } else {
                            self.drafts.insert(folder, at: offset)
                        }
                        
                    }
                }
            }
        case .local(let id):
            if let f = self.folder, !id.isEmpty {
                self.drafts = self.fetchedResultsController.fetchedObjects ?? []
                self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
            } else if AppSettings.draftManualIndexUncategorized.count > 0 {
                AppSettings.draftManualIndexUncategorized.enumerated().forEach { item in
                    let offset = item.offset
                    let element = item.element
                    if let index = self.drafts.firstIndex(where: { $0.id == element.id }) {
                        let folder = self.drafts[index]
                        self.drafts.remove(at: index)
                        if offset > self.drafts.count {
                            self.drafts.insert(folder, at: self.drafts.count)
                        } else {
                            self.drafts.insert(folder, at: offset)
                        }
                    }
                }
            }
        case .cloud: break
        }
    }
    
    func updateSort(sort: SortModel) {
        self.sortModel = sort
    }
    
    func updateFolders(sort: SortModel, isSave: Bool) {
        self.sortModel = sort
        self.drafts = self.fetchedResultsController.fetchedObjects ?? []
        self.rawDrafts = self.fetchedResultsController.fetchedObjects ?? []
        print("========= \(self.fetchedResultsController.fetchRequest.sortDescriptors)")
//        self.documentsEvent.onNext(self.drafts.map { $0.document })
        switch sort.sortName {
        case .manual:
            if isSave {
                self.saveIndex()
            } else {
                self.checkManualIndex()
                self.rearrange()
            }
        case .created_at, .free, .title, .updated_at:
            let docs = self.drafts.map { $0.document }
            self.folder?.documents = docs
            if isSave {
                self.saveIndex()
            }
            
        }
    }
    
    func sortFolder(sort: SortModel, isSave: Bool) {
        do {
            try self.fetchedResultsController.performFetch()
            self.updateFolders(sort: sort, isSave: isSave)
        } catch {
            print("Fetch failed")
        }
        
    }
}
