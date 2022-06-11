//
//  FolderDataSourceProxy.swift
//  GooDic
//
//  Created by ttvu on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import CoreData
import RxSwift
import RxRelay

class FolderDataSourceProxy: NSObject {
    
    struct ManualIndex: Codable {
        let id: String
        let index: Int
    }
    
    enum ExtendedCell {
        case addFolder
        case uncategorizedFolder
    }
    
    var folders: [CDFolder] = []
    var rawFolders: [CDFolder] = []
    let fetchedResultsController: NSFetchedResultsController<CDFolder>
    let extendedCells: [FolderCellType]
    let foldersEvent: BehaviorSubject<[CDFolder]> = BehaviorSubject.init(value: [])
    let saveFoldersEvent: BehaviorRelay<Bool?> = BehaviorRelay.init(value: nil)
    
    init(fetchedResultsController: NSFetchedResultsController<CDFolder>, extendedCells: [FolderCellType] = []) {
        self.fetchedResultsController = fetchedResultsController
        self.extendedCells = extendedCells
        super.init()
    }
    
    func setResultsControllerDelegate(frcDelegate: NSFetchedResultsControllerDelegate) {
        self.fetchedResultsController.delegate = frcDelegate
        do {
            try self.fetchedResultsController.performFetch()
            self.updateFolders(sort: AppSettings.sortModel, isSave: false)
            self.foldersEvent.onNext(self.folders)
        } catch {
            print("Fetch failed")
        }
    }
    
    func numberOfSections() -> Int {
        return (self.fetchedResultsController.sections?.count ?? 0) + 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        if section == 0 {
            return extendedCells.count // create new folder (faked button) and uncategorized folder
        }
        
        return self.folders.count
    }
    
    func folder(at indexPath: IndexPath) -> Folder {
        let data = dataIndexPath(from: indexPath)
        
        
        switch data {
        case .unknown:
            return Folder(name: "unknown", id: .none, manualIndex: nil, hasSortManual: false)
        case .addFolder:
            return Folder(name: L10n.Folder.createFolder, id: .none, manualIndex: nil, hasSortManual: false)
        case .uncategorizedFolder:
            return Folder.uncatetorizedLocalFolder
        case let .folder(dataIndexPath):
            return self.folders[dataIndexPath.row].folder
        }
    }
    
    func getIndexPathDelete(at indexPath: IndexPath?) -> IndexPath? {
        //Section 1 is uncategories
        if let indexPath = indexPath {
            if let indexFolder = self.folders.firstIndex(where: { $0.id == self.rawFolders[indexPath.row].id }) {
                return IndexPath(row: indexFolder, section: indexPath.section)
            }
        }
        return nil
    }
    
    func getIndexInsert() -> IndexPath? {
        return IndexPath(row: self.folders.count, section: 1)
    }
    
    private func rearrange() {
        let list = AppSettings.manualIndex
        list.enumerated().forEach { item in
            let element = item.element
            if (self.folders.firstIndex(where: { $0.id == element.id }) == nil) {
                if let index = AppSettings.manualIndex.firstIndex(where: { $0.id == element.id }) {
                    AppSettings.manualIndex.remove(at: index)
                }
                
            }
        }
        
        if AppSettings.manualIndex.count > 0 {
            AppSettings.manualIndex.enumerated().forEach { item in
                let offset = item.offset
                let element = item.element
                if let index = self.folders.firstIndex(where: { $0.id == element.id }) {
                    let folder = self.folders[index]
                    self.folders.remove(at: index)
                    if offset >= self.folders.count {
                        self.folders.insert(folder, at: self.folders.count)
                    } else {
                        self.folders.insert(folder, at: offset)
                    }
                    
                }
            }
        }
        AppSettings.manualIndex = []
        AppManager.shared.folders = self.folders
        self.saveFoldersEvent.accept(true)
    }
    
    func updateFolders() {
        self.folders = self.fetchedResultsController.fetchedObjects ?? []
        self.rawFolders = self.fetchedResultsController.fetchedObjects ?? []
        print("======= sort folder \(self.fetchedResultsController.fetchRequest.sortDescriptors)")
        self.foldersEvent.onNext(self.folders)
        AppManager.shared.folders = self.folders
    }
    
    
    func updateFolders(sort: SortModel, isSave: Bool) {
        self.folders = self.fetchedResultsController.fetchedObjects ?? []
        self.rawFolders = self.fetchedResultsController.fetchedObjects ?? []
        if isSave {
            self.foldersEvent.onNext(self.folders)
        }
        AppManager.shared.folders = self.folders
        
        //This code use to update folder when launch from 1.2.8 >>> 1.2.9
        if AppSettings.isFirstLaunchGreaterThan128 {
            switch sort.sortName {
            case .manual:
                self.rearrange()
            case .created_at, .free, .updated_at, .title: break
            }
            AppSettings.isFirstLaunchGreaterThan128 = false
            AppSettings.manualIndex = []
        }
    }
    
    func dataIndexPath(from uiIndexPath: IndexPath) -> FolderCellType {
        if uiIndexPath.section == 0 {
            if extendedCells.count > uiIndexPath.row {
                return extendedCells[uiIndexPath.row]
            } else {
                return .unknown
            }
        }
        
        return .folder(IndexPath(row: uiIndexPath.row, section: uiIndexPath.section - 1))
    }
    
    func sortFolder(isSave: Bool) {
        FetchRequestUpdate.share.requestValue()
        do {
            try self.fetchedResultsController.performFetch()
            self.updateFolders(sort: AppSettings.sortModel, isSave: isSave)
        } catch {
            print("Fetch failed")
        }
        
    }
}
