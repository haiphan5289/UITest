//
//  Document.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public enum DocumentStatus: Int {
    case normal = 0
    case deleted = 9
}

public protocol DocumentParams {
    var paramTitle: String? { get }
    var paramContent: String? { get }
    var paramId: String? { get }
    var paramCreatedAt: Date? { get }
    var paramUpdatedAt: Date? { get }
    var paramStatus: DocumentStatus { get }
    var paramFolderId: FolderId { get }
    var paramCursorPosition: Int { get }
    var paramManualIndex: Int? { get }
}

public struct Document {
    var title: String
    var content: String
    var id: String
    var createdAt: Date
    var updatedAt: Date
    var status: DocumentStatus = .normal
    var folderId: FolderId
    var folderName: String = ""
    var cursorPosition: Int
    var manualIndex: Int?
    
    var onCloud: Bool {
        if case .cloud(_) = folderId {
            return true
        }
        
        return false
    }
    
    init() {
        self.init(title: "", content: "", manualIndex: nil)
    }
    
    init(title: String, content: String, folderId: String? = nil, manualIndex: Int?) {
        self.title = title
        self.content = content
        self.id = UUID().uuidString
        self.createdAt = Date()
        self.updatedAt = self.createdAt
        self.folderId = .local(folderId == nil ? "" : folderId!)
        self.cursorPosition = 0
    }
    
    init(title: String, content: String, id: String, createdAt: Date, updatedAt: Date, status: DocumentStatus = .normal, folderId: FolderId, folderName: String = "", cursorPosition: Int, manualIndex: Int?) {
        self.title = title
        self.content = content
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.folderId = folderId
        self.folderName = folderName
        self.cursorPosition = cursorPosition
        self.manualIndex = manualIndex
    }
    
    func getFolderName() -> String? {
        if case let FolderId.local(id) = self.folderId {
            return CDFolder.get(id)?.name
        }
        
        return nil
    }
    
    func duplicate() -> Document {
        var newDocument = self
        newDocument.id = UUID().uuidString
        return newDocument
    }
}

extension Document: DocumentParams {
    public var paramTitle: String? { title }
    public var paramContent: String? { content }
    public var paramId: String? { id }
    public var paramCreatedAt: Date? { createdAt }
    public var paramUpdatedAt: Date? { updatedAt }
    public var paramStatus: DocumentStatus { status }
    public var paramFolderId: FolderId { folderId }
    public var paramCursorPosition: Int { cursorPosition }
    public var paramManualIndex: Int? { manualIndex }
}
