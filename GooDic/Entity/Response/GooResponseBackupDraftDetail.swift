//
//  GooResponseBackupDraftDetail.swift
//  GooDic
//
//  Created by Vinh Nguyen on 05/05/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseBackupDraftDetail: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var title: String
    private(set) var content: String
    private(set) var updatedAt: Date
    private(set) var device: String
    private(set) var cursorPosition: Int

    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case title = "title"
        case content = "text"
        case updatedAt = "last_update"
        case device = "device"
        case cursorPosition = "cursor_position"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        content = (try? container.decode(String.self, forKey: .content)) ?? ""
        device = (try? container.decode(String.self, forKey: .device)) ?? ""
        cursorPosition = (try? container.decode(Int.self, forKey: .device)) ?? 0

        
        let timeStr = (try? container.decode(String.self, forKey: .updatedAt)) ?? ""
        updatedAt = FormatHelper.dateFormatterOnGatewayCloud.date(from: timeStr) ?? Date()
        
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
