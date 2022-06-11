//
//  FetchRequestCoreData.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import CoreData

class FetchRequestUpdate {
    static var share = FetchRequestUpdate()
    var request: NSFetchRequest<CDFolder>!
    let entityName = String(describing: CDFolder.self)
    init() {
        self.request = NSFetchRequest(entityName: entityName)
        if let sort = self.sortRequest() {
            request.sortDescriptors = [sort]
        } else {
            request.sortDescriptors = []
        }
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = false
    }
    
    func sortRequest() -> NSSortDescriptor? {
        var sort: NSSortDescriptor!
        
        switch AppSettings.sortModel.sortName {
        case .free: break
        case .manual:
            sort = NSSortDescriptor(key: "manualIndex", ascending: false)
        case .updated_at:
            sort = NSSortDescriptor(key: "updatedAt", ascending: AppSettings.sortModel.asc)
        case .created_at:
            sort = NSSortDescriptor(key: "createdAt", ascending: AppSettings.sortModel.asc)
        case .title:
            sort = NSSortDescriptor(key: "name", ascending: AppSettings.sortModel.asc)
        }
        return sort
    }
    
    func requestValue() {
        if let sort = self.sortRequest() {
            request.sortDescriptors = [sort]
        } else {
            request.sortDescriptors = []
        }
        
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = false
    }
}
