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
    let text: String
    let updatedAt: Date
    let folderId: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case text = "text"
        case updatedAt = "last_update"
        case folderId = "folder_id"
    }
}
