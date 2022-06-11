//
//  DeviceInfoData.swift
//  GooDic
//
//  Created by ttvu on 11/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct DeviceInfo: Codable {
    let id: String
    let name: String
    let registeredDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case registeredDate = "regist_date"
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? ""
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        registeredDate = (try? container.decode(String.self, forKey: .registeredDate)) ?? ""
    }
}
