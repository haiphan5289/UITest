//
//  CoreDataStack.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataStack {
    var persistentContainer: NSPersistentContainer { get }
    func saveContext()
}

class CoreDataStackImplementation: CoreDataStack {
    
    static let shared = CoreDataStackImplementation()
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "GooDic")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    lazy var persistentContainerQueue:OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()
    
    func enqueue(block: @escaping (_ context: NSManagedObjectContext) -> Void, complete: @escaping () -> Void, errorBlock: @escaping () -> Void) {
        persistentContainerQueue.addOperation(){
            let context: NSManagedObjectContext = self.context
            context.performAndWait{
                block(context)
                do {
                    try self.trySaveContext()
                    complete()
                } catch {
                    errorBlock()
                }
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                checkAndUpdate()
                try context.save()
            } catch {
                let nserror = error as NSError
                assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func trySaveContext() throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            
            checkAndUpdate()
            
            try context.save()
        }
    }
    
    private func checkAndUpdate() {
        for object in context.updatedObjects {
            if let obj = object as? SignProtocol {
                obj.sign()
            }
        }

        for object in context.insertedObjects {
            if let obj = object as? SignProtocol {
                obj.sign()
            }
        }
    }
    
    func getObjects<EntityType>(entityType: EntityType, field: String, value: String) -> [NSManagedObject] {
        let entityName = String(describing: entityType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let predicate = NSPredicate(format: "%K == %@", field, value)
        fetchRequest.predicate = predicate
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(fetchRequest)
            
            return result as! [NSManagedObject]

        } catch {
            print("error: \(error)")
        }
        
        return []
    }
    
    func getObjects<EntityType>(entityType: EntityType, field: String, value: Bool) -> [NSManagedObject] {
        let entityName = String(describing: entityType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let predicate = NSPredicate(format: "%K == %@", field, NSNumber(value: value))
        fetchRequest.predicate = predicate
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(fetchRequest)
            
            return result as! [NSManagedObject]
            
        } catch {
            print("error: \(error)")
        }
        
        return []
    }
    
    func getObject(withURL url: URL) -> NSManagedObject? {
        guard let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else { return nil }
        return try? context.existingObject(with: objectID)
    }
    
    func deleteObjects<EntityType>(entityType: EntityType, field: String, values: [String]) throws {
        let entityName = String(describing: entityType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let predicate = NSPredicate(format: "%K IN %@", field, values)
        fetchRequest.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try context.execute(deleteRequest)
        
        guard  let deleteResult = result as? NSBatchDeleteResult,
               let ids = deleteResult.result as? [NSManagedObjectID] else {
            return
        }
        
        let changes = [NSDeletedObjectsKey: ids]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
}
