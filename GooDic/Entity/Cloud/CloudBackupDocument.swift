//
//  CloudBackupDocument.swift
//  GooDic
//
//  Created by Vinh Nguyen on 04/05/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct CloudBackupDocument: Codable {
    let id: String
    let title: String
    let content: String
    let updatedAt: Date
    let device: String
    let cursorPosition: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case content = "text"
        case updatedAt = "last_update"
        case device = "device"
        case cursorPosition = "cursor_position"
    }
    
    public init(id: String, title: String, content: String, updatedAt: Date, device: String, cursorPosition: Int) {
        self.id = id
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
        self.device = device
        self.cursorPosition = cursorPosition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        device = (try? container.decode(String.self, forKey: .device)) ?? ""
        cursorPosition = (try? container.decode(Int.self, forKey: .cursorPosition)) ?? 0
        
        let timeStr = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = FormatHelper.dateFormatterOnGatewayCloud.date(from: timeStr) ?? Date()
    }
}
