//
//  DatabaseCoreDataGateway.swift
//  GooDic
//
//  Created by ttvu on 6/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

struct DatabaseCoreDataGateway: DatabaseGatewayProtocol {
    
    func get(document: Document) -> Observable<CDDocument> {
        return Observable.create { observer in
            if let item = CDDocument.get(document.id) {
                observer.onNext(item)
            } else {
                observer.onError(NSError())
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func bin(document: Document) -> Observable<Void> {
        return update(document: document, withState: .deleted)
    }
    
    func pushBack(document: Document) -> Observable<Void> {
        return update(document: document, withState: .normal)
    }
    
    // Do not update the updatedAt attribute.
    private func update(document: Document, withState state: DocumentStatus) -> Observable<Void> {
        return Observable.create { observer in
            if let item = CDDocument.get(document.id) {
                
                item.insertStatus = Int16(state.rawValue)
                
                do {
                    try CoreDataStackImplementation.shared.trySaveContext()
                    observer.onNext(())
                } catch {
                    observer.onError(error)
                }
            } else {
                observer.onError(NSError())
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func delete(documents: [Document]) -> Observable<Void> {
        return Observable.create { observer in
            var hasItem = false
            
            documents.forEach { (doc) in
                if let item = CDDocument.get(doc.id) {
                    CoreDataStackImplementation.shared.context.delete(item)
                    hasItem = true
                }
            }
            
            if hasItem {
                do {
                    try CoreDataStackImplementation.shared.trySaveContext()
                    observer.onNext(())
                } catch {
                    observer.onError(error)
                }
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func update(document: Document) -> Observable<Void> {
        return Observable.create { observer in
            var item = CDDocument.get(document.id)
            
            if item == nil {
                item = CDDocument(context: CoreDataStackImplementation.shared.context)
            }
            
            item!.update(with: document)
            item!.updatedAt = Date()
            
            do {
                try CoreDataStackImplementation.shared.trySaveContext()
                observer.onNext(())
            } catch {
                observer.onError(error)
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func getFolder(with name: String) -> Observable<[CDFolder]> {
        return Observable.create { observer in
            let draftFetch: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            let predicate =  NSPredicate(format: "name ==[c] %@", name)
            draftFetch.predicate = predicate

            do {
                let results = try CoreDataStackImplementation.shared.context.fetch(draftFetch)
                observer.onNext(results)
            } catch {
                observer.onError(error)
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func move(document: Document, to folderIds: [String]) -> Observable<String?> {
        return Observable.create { observer in
            let item = CDDocument.get(document.id)
            
            let destinationFolders = folderIds.map({ return CDFolder.get($0) })
                .compactMap({ $0 })
            
            if let item = item {
                // remove all folder references to its
                if let folders = item.folders {
                    item.removeFromFolders(folders)
                }
                
                destinationFolders.forEach { (folder) in
                    folder.addToDocuments(item)
                }
                
                let anyFolderId = (item.folders?.anyObject() as? CDFolder)?.id
                
                do {
                    try CoreDataStackImplementation.shared.trySaveContext()
                    observer.onNext(anyFolderId)
                } catch {
                    observer.onError(error)
                }
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func update(folder: Folder) -> Observable<Void> {
        return Observable.create { observer in
            var item = CDFolder.get(folder.id)
            
            if item == nil {
                item = CDFolder(context: CoreDataStackImplementation.shared.context)
            }
            
            item!.update(with: folder)
            item!.updatedAt = Date()
            
            do {
                try CoreDataStackImplementation.shared.trySaveContext()
                observer.onNext(())
            } catch {
                observer.onError(error)
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func delete(folder: Folder) -> Observable<Void> {
        return Observable.create { observer in
            if let item = CDFolder.get(folder.id) {
                CoreDataStackImplementation.shared.context.delete(item)
                
                do {
                    try CoreDataStackImplementation.shared.trySaveContext()
                    observer.onNext(())
                } catch {
                    observer.onError(error)
                }
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func getUncategorizedDocuments() -> Observable<[CDDocument]> {
        return Observable.create { observer in
            let draftFetch: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
            let predicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue), NSPredicate(format: "folders.@count == 0")])
            draftFetch.predicate = predicate

            do {
                let drafts = try CoreDataStackImplementation.shared.context.fetch(draftFetch)
                observer.onNext(drafts)
            } catch {
                observer.onError(error)
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
