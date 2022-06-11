//
//  Folder.swift
//  GooDic
//
//  Created by ttvu on 9/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public enum FolderId: Equatable{
    case none
    case local(String)
    case cloud(String)
    
    var cloudID: String? {
        if case let .cloud(id) = self {
            return id
        }
        
        return nil
    }
    
    var localID: String? {
        if case let .local(id) = self {
            return id
        }
        
        return nil
    }
    
    static func findSameFolderId(_ folderIds: [FolderId]) -> FolderId {
        // if all drafts are in the same folder, return the related folder
        if let firstFolderId = folderIds.first {
            let differentFolder = folderIds.first { (item) -> Bool in
                if item != firstFolderId {
                    return true
                }

                return false
            }

            if differentFolder == nil {
                return firstFolderId
            }
        }

        return .none
    }
}

public struct Folder {
    static let uncatetorizedLocalFolder = Folder(name: L10n.Folder.uncategorized, id: .local(""), manualIndex: nil, hasSortManual: false)
    static let uncatetorizedCloudFolder = Folder(name: L10n.Folder.uncategorized, id: .cloud(""), manualIndex: nil, hasSortManual: false)
    
    var id: FolderId
    var createdAt: Date
    var updatedAt: Date
    var name: String
    var documents: [Document]
    var sortModelData: Data?
    var manualIndex: Double?
    var hasSortManual: Bool?
    
    var onCloud: Bool {
        if case .cloud(_) = id {
            return true
        }
        
        return false
    }
    
    init(name: String, numOfDocs: Int, manualIndex: Double?, hasSortManual: Bool) {
        let number = numOfDocs >= 0 ? numOfDocs : 0
        self.init(name: name, documents: [Document](repeating: Document(), count: number), manualIndex: manualIndex, hasSortManual: hasSortManual)
    }
    
    init(name: String, id: FolderId, numOfDocs: Int, manualIndex: Double?, hasSortManual: Bool) {
        let number = numOfDocs >= 0 ? numOfDocs : 0
        self.init(name: name, id: id, documents: [Document](repeating: Document(), count: number), manualIndex: manualIndex, hasSortManual: hasSortManual)
    }
    
    init(name: String, documents: [Document] = [], sortModelData: Data? = nil, manualIndexData: Data? = nil, manualIndex: Double?, hasSortManual: Bool) {
        self.init(name: name, id: .local(UUID().uuidString), documents: documents, sortModelData: sortModelData, manualIndex: manualIndex, hasSortManual: hasSortManual)
    }
    
    init(name: String, id: FolderId, documents: [Document] = [], sortModelData: Data? = nil, manualIndex: Double?, hasSortManual: Bool) {
        self.name = name
        self.id = id
        self.createdAt = Date()
        self.updatedAt = self.createdAt
        self.documents = documents
        self.sortModelData = sortModelData
        self.manualIndex = manualIndex
        self.hasSortManual = hasSortManual
    }
    
    init(name: String, id: String, createdAt: Date, updatedAt: Date, documents: [Document] = [], sortModelData: Data? = nil, manualIndex: Double?, hasSortManual: Bool) {
        self.name = name
        self.id = .local(id)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.documents = documents
        self.sortModelData = sortModelData
        self.manualIndex = manualIndex
        self.hasSortManual = hasSortManual
    }
    
    func getSortModel() -> SortModel {
        guard let data = self.sortModelData else {
            return SortModel.valueDefaultDraft
        }
        
        guard let model = data.toCodableObject(type: SortModel.self) else {
            return SortModel.valueDefaultDraft
        }
        
        return model
    }
}
