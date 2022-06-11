//
//  GooResponseDocuments.swift
//  GooDic
//
//  Created by ttvu on 12/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseDocuments: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var total: Int
    private(set) var offset: Int
    private(set) var limit: Int //
    private(set) var folderId: String
    private(set) var folderName: String
    private(set) var data: [CloudDocument]
    private(set) var sortedAt: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case total = "total"
        case offset = "offset"
        case limit = "limit"
        case folderId = "folder_id"
        case folderName = "folder_name"
        case data = "documents"
        case sortedAt = "sorted_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        total = (try? container.decode(Int.self, forKey: .total)) ?? 0
        let offsetStr = (try? container.decode(String.self, forKey: .offset)) ?? "0"
        offset = Int(offsetStr) ?? 0
        let limitStr = (try? container.decode(String.self, forKey: .limit)) ?? "0"
        limit = Int(limitStr) ?? 0
        
        folderId = (try? container.decode(String.self, forKey: .folderId)) ?? ""
        folderName = (try? container.decode(String.self, forKey: .folderName)) ?? ""
        
        data = (try? container.decode([CloudDocument].self, forKey: .data)) ?? []
        sortedAt = (try? container.decode(String.self, forKey: .sortedAt)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
