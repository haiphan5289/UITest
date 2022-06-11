//
//  GooResponseStatusCode.swift
//  GooDic
//
//  Created by ttvu on 12/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseStatusCode: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
