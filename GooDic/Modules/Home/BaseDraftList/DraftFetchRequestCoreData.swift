//
//  DraftFetchRequestCoreData.swift
//  GooDic
//
//  Created by haiphan on 21/02/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation
import CoreData

class DraftFetchRequestCoreData {
    static var share = DraftFetchRequestCoreData()
    var request: NSFetchRequest<CDDocument>!
    let entityName = String(describing: CDDocument.self)
    var predicate: NSPredicate?
    init(query: FolderId = .none) {
        switch query {
        case .none:
            predicate = NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue)
            
        case let .local(id):
            if id.isEmpty {
                predicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue), NSPredicate(format: "folders.@count == 0")])
            } else {
                predicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "insertStatus == %d", DocumentStatus.normal.rawValue), NSPredicate(format: "SUBQUERY(folders, $folder, $folder.id == %@).@count > 0", id)])
            }
            
            
        case .cloud(_):
            assertionFailure("a cloudId can't use to get data at local")
            break
        }
        self.request = NSFetchRequest(entityName: entityName)
        self.request.predicate = predicate
        self.request.sortDescriptors = []
        self.request.fetchBatchSize = 20
        self.request.returnsObjectsAsFaults = false
    }
    
    func sortRequest() -> NSSortDescriptor? {
        var sort: NSSortDescriptor!
        
        switch AppSettings.sortModelDrafts.sortName {
        case .free: break
        case .manual:
            return nil
        case .updated_at:
            sort = NSSortDescriptor(key: "updatedAt", ascending: AppSettings.sortModel.asc)
        case .created_at:
            sort = NSSortDescriptor(key: "createdAt", ascending: AppSettings.sortModel.asc)
        case .title:
            sort = NSSortDescriptor(key: "title", ascending: AppSettings.sortModel.asc)
        }
        return sort
    }
    
    func requestValue() {
        self.request.predicate = predicate
        if let sort = self.sortRequest() {
            request.sortDescriptors = [sort]
        } else {
            request.sortDescriptors = []
        }
        
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = false
    }
}
