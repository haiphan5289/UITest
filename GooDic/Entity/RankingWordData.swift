//
//  RankingWordData.swift
//  GooDic
//
//  Created by ttvu on 7/9/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct RankingWordData: Codable {
    
    var id: UUID = UUID()
    
    var rank: Int
    var word: String
    var url: String
    
    enum CodingKeys: String, CodingKey {
        case rank = "rank"
        case word = "word"
        case url = "url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rankStr = try container.decode(String.self, forKey: .rank)
        self.rank = Int(rankStr) ?? 0
        self.word = try container.decode(String.self, forKey: .word)
        self.url = try container.decode(String.self, forKey: .url)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(self.rank)", forKey: .rank)
        try container.encode(word, forKey: .word)
        try container.encode(url, forKey: .url)
    }
}
