//
//  CDDocument.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import CoreData

protocol SignProtocol {
    func sign()
}

extension CDDocument: SignProtocol {
    
    var document: Document {
        let folderIdValue = folders?
            .map({ (item) -> String? in
                return (item as? CDFolder)?.id
            })
            .compactMap({ $0 })
            .first
        
        let folderId = FolderId.local(folderIdValue == nil ? "" : folderIdValue!)
        
        return Document(title: title ?? "",
                        content: content ?? "",
                        id: id ?? UUID().uuidString,
                        createdAt: createdAt ?? Date(),
                        updatedAt: updatedAt ?? Date(),
                        status: DocumentStatus(rawValue: Int(insertStatus)) ?? DocumentStatus.normal,
                        folderId: folderId,
                        cursorPosition: Int(cursorPosition),
                        manualIndex: Int(manualIndex))
    }
    
    // do not manualy update "createdAt", let CoreDataStack does it for you
    func update(with parametes: DocumentParams) {
        id = parametes.paramId
        title = parametes.paramTitle
        insertStatus = Int16(parametes.paramStatus.rawValue)
        content = parametes.paramContent
        cursorPosition = Int32(parametes.paramCursorPosition)
        updatedAt = parametes.paramUpdatedAt
        manualIndex = Double((parametes.paramManualIndex ?? 0))
        
        if let folders = folders {
            removeFromFolders(folders)
        }
        
        if case let .local(id) = parametes.paramFolderId, let folder = CDFolder.get(id) {
            addToFolders([folder])
        }
    }
    
    // called by CoreDataStack
    func sign() {
        if createdAt == .none {
            if updatedAt == .none {
                let now = Date()
                
                createdAt = now
                updatedAt = now
            } else {
                createdAt = updatedAt
            }
        }
    }
}

extension CDDocument: DocumentParams {
    public var paramManualIndex: Int? { Int(manualIndex) }
    public var paramTitle: String? { title }
    public var paramContent: String? { content }
    public var paramId: String? { id }
    public var paramCreatedAt: Date? { createdAt }
    public var paramUpdatedAt: Date? { updatedAt }
    public var paramStatus: DocumentStatus { DocumentStatus(rawValue: Int(insertStatus)) ?? DocumentStatus.normal }
    public var paramFolderId: FolderId {
        guard let folders = folders else { return .local("") }
        let folderIdValue = folders
            .map({ (item) -> String? in
                return (item as? CDFolder)?.id
            })
            .compactMap({ $0 })
            .first
 
        return .local(folderIdValue == nil ? "" : folderIdValue!)
    }
    public var paramCursorPosition: Int { Int(cursorPosition) }
}

extension CDDocument {
    class func get(_ id: String) -> CDDocument? {
        let item = CoreDataStackImplementation.shared.getObjects(entityType: CDDocument.self, field: "id", value: id).first as? CDDocument
        
        return item?.isDeleted == false ? item : nil
    }
}
