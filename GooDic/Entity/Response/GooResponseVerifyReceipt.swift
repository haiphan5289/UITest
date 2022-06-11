//
//  GooResponseVerifyReceipt.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/14/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseVerifyReceipt: Codable {
    private(set) var valid: Bool
    private(set) var errors: [String]
    
    enum CodingKeys: String, CodingKey {
        case valid = "valid"
        case errors = "errors"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        valid = try container.decode(Bool.self, forKey: .valid)
        errors = (try? container.decode([String].self, forKey: .errors)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
