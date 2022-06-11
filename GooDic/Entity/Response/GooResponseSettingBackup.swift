//
//  GooResponseSettingBackup.swift
//  GooDic
//
//  Created by Vinh Nguyen on 22/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation

public struct GooResponseSettingBackup: Codable {
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    private(set) var value: SettingBackupModel?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case errorCode = "error_code"
        case value = "setting_value"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
        let jsonString = (try? container.decode(String.self, forKey: .value))
        if let data = jsonString?.data(using: .utf8) {
            value = try? JSONDecoder().decode(SettingBackupModel.self, from: data)
        }
        
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
    
        

    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
