//
//  GooResponseDocumentDetail.swift
//  GooDic
//
//  Created by ttvu on 12/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseDocumentDetail: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var title: String
    private(set) var text: String
    private(set) var cursorPosition: Int
    private(set) var update: Date
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case title = "document_title"
        case text = "document_text"
        case cursorPosition = "cursor_position"
        case update = "document_last_update"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        
        let timeStr = (try? container.decode(String.self, forKey: .update)) ?? ""
        update = FormatHelper.dateFormatterOnGatewayCloud.date(from: timeStr) ?? Date()
        
        cursorPosition = (try? container.decode(Int.self, forKey: .cursorPosition)) ?? 0
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
