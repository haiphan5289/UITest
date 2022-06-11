//
//  GooResponseUpdateDocument.swift
//  GooDic
//
//  Created by ttvu on 1/21/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseUpdateDocument: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var lastUpdate: Date
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case lastUpdate = "last_updated_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        
        let timeStr = (try? container.decode(String.self, forKey: .lastUpdate)) ?? ""
        lastUpdate = FormatHelper.dateFormatterOnGatewayCloud.date(from: timeStr) ?? Date()
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
