//
//  ThesaurusData.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct ThesaurusData: Codable, GooDataProtocol {
    
    var id: UUID = UUID()
    
    var target: String
    var index: Int
    var list: [String]
    var url: String
    var offset: Int
    
    enum CodingKeys: String, CodingKey {
        case target = "target"
        case index = "index"
        case list = "list"
        case url = "url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        target = try container.decode(String.self, forKey: .target)
        list = try container.decode([String].self, forKey: .list)
        url = try container.decode(String.self, forKey: .url)
        index = (try? container.decode(Int.self, forKey: .index)) ?? -1
        offset = 1
    }
}
