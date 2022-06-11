//
//  CoreDataHelper.swift
//  GooDic
//
//  Created by ttvu on 6/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import CoreData

func createFetchedResultsController<T: NSManagedObject>(predicate: NSPredicate?) -> NSFetchedResultsController<T> {
     let sort = NSSortDescriptor(key: "updatedAt", ascending: false)
     return createFetchedResultsController(sorts: [sort], predicate: predicate)
 }

func createFetchedResultsController<T: NSManagedObject>(sorts: [NSSortDescriptor], predicate: NSPredicate? ) -> NSFetchedResultsController<T> {
    let entityName = String(describing: T.self)
    let request: NSFetchRequest<T> = NSFetchRequest(entityName: entityName)
    request.predicate = predicate
    request.sortDescriptors = sorts
    request.fetchBatchSize = 20
    request.returnsObjectsAsFaults = false
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStackImplementation.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    
    return fetchedResultsController
}

func createFetchedResultsControllerDraft<T: NSManagedObject>(request: NSFetchRequest<T> ) -> NSFetchedResultsController<T> {
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStackImplementation.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    
    return fetchedResultsController
}


func createFetchedResultsControllerCDFolder(request: NSFetchRequest<CDFolder> ) -> NSFetchedResultsController<CDFolder> {
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStackImplementation.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    
    return fetchedResultsController
}
