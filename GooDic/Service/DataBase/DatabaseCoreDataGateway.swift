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
            
            CoreDataStackImplementation.shared.enqueue(block: { writeContext in
                if let item = CDDocument.get(document.id) {
                    item.insertStatus = Int16(state.rawValue)
                    
                    // remove the relationship with folders when moving a draft to trash
                    if state == .deleted, let folders = item.folders {
                        item.removeFromFolders(folders)
                    }
                }
            }, complete: {
                observer.onNext(())
                observer.onCompleted()
            }, errorBlock: {
                observer.onError(NSError())
            })
            return Disposables.create()
        }
    }
    
    func delete(documents: [Document]) -> Observable<Void> {
        return Observable.create { observer in
            CoreDataStackImplementation.shared.enqueue(block: { writeContext in
                documents.forEach { (doc) in
                    if let item = CDDocument.get(doc.id) {
                        writeContext.delete(item)
                    }
                }
                observer.onNext(())
            }, complete: {
                observer.onCompleted()
            }, errorBlock: {
                observer.onError(NSError())
            })
                return Disposables.create()
            }
    }
    
    func updateDocs(document: Document, updateDate: Bool = true) {
        var item = CDDocument.get(document.id)
        
        if item == nil {
            item = CDDocument(context: CoreDataStackImplementation.shared.context)
        }
        
        item!.update(with: document)
        
        if updateDate {
            item!.updatedAt = Date()
        }
        
        do {
            try CoreDataStackImplementation.shared.trySaveContext()
        } catch {
        }
    }
    
    func checkIsDocument(document: Document) -> Bool {
        if CDDocument.get(document.id) == nil {
            return false
        } else {
            return true
        }
    }
    
    func update(document: Document, updateDate: Bool = true) -> Observable<Void> {
        return Observable.create { observer in
            var item = CDDocument.get(document.id)
            
            if item == nil {
                item = CDDocument(context: CoreDataStackImplementation.shared.context)
            }
            
            item!.update(with: document)
            
            if updateDate {
                item!.updatedAt = Date()
            }
            
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
    
    func create(document: Document) -> Observable<Void> {
        return Observable.create { observer in
            let item = CDDocument(context: CoreDataStackImplementation.shared.context)
            item.createdAt = Date()
            item.update(with: document)
            
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
    
    func getFolder(with name: String) -> [CDFolder] {
        let draftFetch: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
        let predicate =  NSPredicate(format: "name ==[c] %@", name)
        draftFetch.predicate = predicate

        do {
            let results = try CoreDataStackImplementation.shared.context.fetch(draftFetch)
            return results
        } catch {
            return []
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
    
    func move(document: Document, to folderId: String) -> Observable<Void> {
        return Observable.create { observer in
            let item = CDDocument.get(document.id)
            
            let destinationFolder = CDFolder.get(folderId)
            
            if let item = item {
                // remove all folder references to its
                if let folders = item.folders {
                    item.removeFromFolders(folders)
                }
                item.manualIndex = Double((document.manualIndex ?? 0))
                destinationFolder?.addToDocuments(item)
                
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
    
    func updateSort(folder: Folder)  {
        if case let .local(id) = folder.id {
            var item = CDFolder.get(id)
            
            if item == nil {
                item = CDFolder(context: CoreDataStackImplementation.shared.context)
            }
            
            item!.update(with: folder)
            
            do {
                try CoreDataStackImplementation.shared.trySaveContext()
            } catch {
            }
        }
    }
    
    func update(folder: Folder) -> Observable<Void> {
        return Observable.create { observer in
            if case let .local(id) = folder.id {
                var item = CDFolder.get(id)
                
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
            }
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func delete(folder: Folder) -> Observable<Void> {
        return Observable.create { observer in
            if case let .local(id) = folder.id, let item = CDFolder.get(id) {
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
    
    func getAllDocuments() -> Observable<[CDDocument]> {
        return Observable.create { observer in
            let draftFetch: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
            draftFetch.predicate = NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue)
            draftFetch.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

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
