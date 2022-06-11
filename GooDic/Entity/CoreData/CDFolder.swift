//
//  CDFolder.swift
//  GooDic
//
//  Created by ttvu on 9/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

extension CDFolder: SignProtocol {
    var folder: Folder {
        let documentList = documents?
            .map({ (item) -> Document? in
                return (item as? CDDocument)?.document ?? nil
            })
            .compactMap({ $0 })
        
        return Folder(name: name ?? "",
                      id: id ?? UUID().uuidString,
                      createdAt: createdAt ?? Date(),
                      updatedAt: updatedAt ?? Date(),
                      documents: documentList ?? [],
                      sortModelData: sortModel,
                      manualIndex: (manualIndex),
                      hasSortManual: hasSortManual)
    }
    
    // do not manualy update "createdAt", let CoreDataStack does it for you
    func update(with parametes: Folder) {
        if case let .local(id) = parametes.id {
            self.id = id
        }
        sortModel = parametes.sortModelData
        name = parametes.name
        updatedAt = parametes.updatedAt
        manualIndex = (parametes.manualIndex ?? 0)
        hasSortManual = parametes.hasSortManual ?? false
    }
    
    // called by CoreDataStack
    func sign() {
        let now = Date()
        
        if createdAt == .none {
            createdAt = now
            updatedAt = now
        }
    }
}

extension CDFolder {
    class func get(_ id: String) -> CDFolder? {
        let item = CoreDataStackImplementation.shared.getObjects(entityType: CDFolder.self, field: "id", value: id).first as? CDFolder
        return item?.isDeleted == false ? item : nil
    }
}
