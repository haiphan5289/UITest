//
//  GooResponseFoldersSort.swift
//  GooDic
//
//  Created by haiphan on 07/02/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseFoldersSort: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var sortedAt: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case sortedAt = "sorted_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        sortedAt = (try? container.decode(String.self, forKey: .sortedAt)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
