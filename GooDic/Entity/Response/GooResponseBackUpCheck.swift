//
//  GooResponseBackUpCheck.swift
//  GooDic
//
//  Created by haiphan on 25/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseBackUpCheck: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var backupExist: Bool?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case backupExist = "backup_exist"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        backupExist = (try? container.decode(Bool.self, forKey: .backupExist)) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
