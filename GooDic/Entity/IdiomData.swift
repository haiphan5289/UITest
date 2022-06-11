//
//  IdiomData.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct IdiomData: Codable, GooDataProtocol {
    
    var id: UUID = UUID()
    
    var target: String
    var index: Int
    var correct: String
    var url: String
    var offset: Int
    
    enum CodingKeys: String, CodingKey {
        case target = "target"
        case index = "index"
        case correct = "correct"
        case url = "url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        target = try container.decode(String.self, forKey: .target)
        correct = try container.decode(String.self, forKey: .correct)
        url = try container.decode(String.self, forKey: .url)
        index = (try? container.decode(Int.self, forKey: .index)) ?? 1
        offset = 0
    }
    
    var list: [String] {
        return [correct]
    }
}
