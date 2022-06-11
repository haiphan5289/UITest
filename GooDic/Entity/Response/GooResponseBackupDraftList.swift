//
//  GooResponseBackupDraftList.swift
//  GooDic
//
//  Created by Vinh Nguyen on 04/05/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseBackupDraftList: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var data: [CloudBackupDocument]

    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case data = "backups"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        data = (try? container.decode([CloudBackupDocument].self, forKey: .data)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
