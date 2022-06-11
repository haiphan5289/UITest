//
//  TrashUseCase.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import CoreData
import RxSwift

protocol TrashUseCaseProtocol {
    
    var fetchedResultsController: NSFetchedResultsController<CDDocument> { get }
    
    func pushBack(documents: [Document]) -> Observable<Void>
    func delete(documents: [Document]) -> Observable<Void>
    func deleteAll() -> Observable<Void>
}

struct TrashUseCase: TrashUseCaseProtocol {
    
    @GooInject var dbService: DatabaseService
    var fetchedResultsController: NSFetchedResultsController<CDDocument>
    
    init() {
        fetchedResultsController = createFetchedResultsController(predicate: NSPredicate(format: "insertStatus == %d", DocumentStatus.deleted.rawValue))
    }
    
    mutating func getFetchedResultsController() -> NSFetchedResultsController<CDDocument> {
        return fetchedResultsController
    }
    
    func pushBack(documents: [Document]) -> Observable<Void> {
        let collection = documents.map({ dbService.gateway.pushBack(document: $0) })
        
        return Observable
            .zip(collection)
            .mapToVoid()
    }
    
    func delete(documents: [Document]) -> Observable<Void> {
        let arrDoc = documents.split(subCollectionCount: 20)
        let collection = arrDoc.map({ dbService.gateway.delete(documents: $0) })
        
        return Observable
            .zip(collection)
            .mapToVoid()
    }
    
    func deleteAll() -> Observable<Void> {
        guard let list = fetchedResultsController.fetchedObjects else { return Observable.empty() }
        
        return dbService.gateway.delete(documents: list.map({ $0.document }))
    }
}
