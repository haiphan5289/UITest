//
//  GooResponseBillingInfo.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/3/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

enum BillingStatus: Int, Codable {
    case free = 0
    case paid = 1
}

public struct GooResponseBillingInfo: Codable {
    private(set) var status: GooAPIStatus
    private(set) var billingStatus: BillingStatus
    private(set) var platform: String
    private(set) var errorCode: String
    private(set) var errorMessage: String
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case billingStatus = "billing_status"
        case platform = "platform"
        case errorCode = "error_code"
        case errorMessage = "error_message"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        errorMessage = (try? container.decode(String.self, forKey: .errorMessage)) ?? ""
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        
        if let statusBillingValue = try? container.decode(Int.self, forKey: .billingStatus) {
            billingStatus = BillingStatus(rawValue: statusBillingValue) ?? .free
        } else {
            billingStatus = .free
        }
        
        platform = (try? container.decode(String.self, forKey: .platform)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
