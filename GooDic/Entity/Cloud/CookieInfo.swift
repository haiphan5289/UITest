//
//  CookieInfo.swift
//  GooDic
//
//  Created by ttvu on 12/7/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct CookieInfo: Codable {
    let gooId: String
    let userId: String
    let expired: Date
    
    enum CodingKeys: String, CodingKey {
        case gooId = "GOO_ID"
        case userId = "USER_ID"
        case expired = "GOOID_TICKET_MANAGER_OUTPUT_EXPIRED"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gooId = try container.decode(String.self, forKey: .gooId)
        userId = try container.decode(String.self, forKey: .userId)
        let expiredStr = try container.decode(String.self, forKey: .expired)
        if let timeInterval = Double(expiredStr) {
            expired = Date(timeIntervalSince1970: timeInterval)
        } else {
            expired = Date(timeIntervalSinceNow: 3 * 24 * 60 * 60) // 3 days
        }
    }
}
