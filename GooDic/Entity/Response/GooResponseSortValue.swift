//
//  GooResponseSortValue.swift
//  GooDic
//
//  Created by haiphan on 05/01/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseSortValue: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var value: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case value = "setting_value"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        value = (try? container.decode(String.self, forKey: .value)) ?? ""
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
