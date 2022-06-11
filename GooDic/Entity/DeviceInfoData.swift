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
    let registeredDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case registeredDate = "regist_date"
    }
}
