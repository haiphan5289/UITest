//
//  CloudDocument.swift
//  GooDic
//
//  Created by ttvu on 11/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct CloudDocument: Codable {
    let id: String
    let title: String
    let content: String
    let updatedAt: Date
    let folderId: String
    let folderName: String
    let cursorPosition: Int
    let manualIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case content = "text"
        case updatedAt = "last_update"
        case folderId = "folder_id"
        case folderName = "folder_name"
        case cursorPosition = "cursor_position"
        case manualIndex = "manualIndex: Int?"
    }
    
    public init(id: String, title: String, content: String, updatedAt: Date, folderId: String, folderName: String, cursorPosition: Int, manualIndex: Int?) {
        self.id = id
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
        self.folderId = folderId
        self.folderName = folderName
        self.cursorPosition = cursorPosition
        self.manualIndex = manualIndex
    }
    
    public init(id: String) {
        self.id = id
        self.title = ""
        self.content = ""
        self.updatedAt = Date()
        self.folderId = ""
        self.folderName = ""
        self.cursorPosition = 0
        self.manualIndex = nil
    }
    
    public init?(document: Document) {
        guard let cloudFolderId = document.folderId.cloudID else {
            return nil
        }
        
        self.id = document.id
        self.title = document.title
        self.content = document.content
        self.updatedAt = document.updatedAt
        self.folderId = cloudFolderId
        self.folderName = document.folderName
        self.cursorPosition = document.cursorPosition
        self.manualIndex = document.manualIndex
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        folderId = (try? container.decode(String.self, forKey: .folderId)) ?? ""
        folderName = (try? container.decode(String.self, forKey: .folderName)) ?? ""
        
        let timeStr = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = FormatHelper.dateFormatterOnGatewayCloud.date(from: timeStr) ?? Date()
        
        cursorPosition = (try? container.decode(Int.self, forKey: .cursorPosition)) ?? 0
        manualIndex = (try? container.decode(Int.self, forKey: .manualIndex)) ?? 0
    }
}

extension CloudDocument {
    var document: Document {
        return Document(title: self.title,
                        content: self.content,
                        id: self.id,
                        createdAt: self.updatedAt,
                        updatedAt: self.updatedAt,
                        status: .normal,
                        folderId: .cloud(self.folderId),
                        folderName: self.folderName,
                        cursorPosition: self.cursorPosition,
                        manualIndex: self.manualIndex)
    }
}
