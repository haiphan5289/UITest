//
//  GooResponseDevices.swift
//  GooDic
//
//  Created by ttvu on 12/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseDevices: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var data: [DeviceInfo]
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case data = "devices"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        data = (try? container.decode([DeviceInfo].self, forKey: .data)) ?? []
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
