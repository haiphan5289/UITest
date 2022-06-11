//
//  LocalFoldersUseCase.swift
//  GooDic
//
//  Created by ttvu on 1/15/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

protocol LocalFoldersUseCaseProtocol {
    var fetchedResultsController: NSFetchedResultsController<CDFolder> { get }
    func deleteFolder(folder: Folder) -> Observable<Void>
    
    func showSwipeActionInFolder() -> Bool
    func learnedSwipeFolderTutorial() -> Observable<Void>
    func updateFolder(folder: Folder) -> Observable<Void>
    func updateIndexFolder(folders: [Folder])
}

struct LocalFoldersUseCase: LocalFoldersUseCaseProtocol {
    @GooInject var dbService: DatabaseService
    var fetchedResultsController: NSFetchedResultsController<CDFolder>
    
    init() {
        fetchedResultsController = createFetchedResultsControllerCDFolder(request: FetchRequestUpdate.share.request)
    }
    
    func updateIndexFolder(folders: [Folder]) {
        _ = folders.map {  dbService.gateway.updateSort(folder: $0) }
    }
    
    func updateFolder(folder: Folder) -> Observable<Void> {
        return dbService.gateway.update(folder: folder)
    }
    
    func deleteFolder(folder: Folder) -> Observable<Void> {
        if folder.documents.isEmpty {
            return self.dbService.gateway.delete(folder: folder)
        }
        
        let tasks = folder.documents
            .map({
                Observable.just($0)
                    .flatMap ({ (item) -> Observable<Void> in
                        self.dbService.gateway.bin(document: item)
                    })
            })
        
        return Observable.zip(tasks)
            .mapToVoid()
            .flatMap({ self.dbService.gateway.delete(folder: folder) })
    }
    
    func showSwipeActionInFolder() -> Bool {
        return AppSettings.guideUserToSwipeFolder == false
    }
    
    func learnedSwipeFolderTutorial() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            AppSettings.guideUserToSwipeFolder = true
            
            observer.onNext(())
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
