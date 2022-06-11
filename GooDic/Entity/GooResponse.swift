//
//  GooResponse.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponse<T: Codable>: Codable {
    
    var statusValue: Int { Int(status ?? "0") ?? 0 }
    var result: GooResultType {
        if statusValue == 99 {
            return GooResultType.error(.otherError(""))
        }
        
        if let data = data {
            return .normal(data)
        }
        
        return .empty
    }
    
    // Raw data
    private let status: String?
    private let errorMessage: String?
    private let data: T?
    private let devices: T?
    private let deviceName: T?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorMessage = "error_message"
        case data = "data"
        case devices = "devices"
        case deviceName = "device_name"
    }
    
    enum GooResultType {
        case error(GooServiceError)
        case empty
        case normal(T)
    }
}


