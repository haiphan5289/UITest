//
//  DeleteDevice.swift
//  GooDic
//
//  Created by paxcreation on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

struct DeleteDeviceModel: Codable {
    private(set) var status: GooAPIStatus
    enum CodingKeys: String, CodingKey {
        case status = "status"
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}
struct DeviceName: Codable {
    let deviceName: String
    private(set) var status: GooAPIStatus
    private(set) var errorCode: String
    enum CodingKeys: String, CodingKey {
        case deviceName = "device_name"
        case status = "status"
        case errorCode = "error_code"
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decode(String.self, forKey: .status)
        status = GooAPIStatus(rawValue: statusValue) ?? .normal
        deviceName = (try? container.decode(String.self, forKey: .deviceName)) ?? ""
        errorCode = (try? container.decode(String.self, forKey: .errorCode)) ?? ""
    }
    
    public func encode(to encoder: Encoder) throws {
        // DO NOTHING
    }
}

