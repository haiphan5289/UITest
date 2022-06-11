//
//  SettingBackupModel.swift
//  GooDic
//
//  Created by Vinh Nguyen on 22/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import Foundation
import UIKit


public struct SettingBackupModel: Codable {
    public enum SettingKey {
        case backupSettings

        var textParam: String {
            switch self {
            case .backupSettings: return "backupSettings"
            }
        }
    }
    
    
    let isBackup: Bool?
    let isManualSaveBackup: Bool?
    let isPeriodicBackup: Bool?
    let interval: Int?
    
    
    enum CodingKeys: String, CodingKey {
        case isBackup = "is_backup"
        case isManualSaveBackup = "is_manual_save_backup"
        case isPeriodicBackup = "is_periodic_backup"
        case interval = "interval"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isBackup = (try? container.decode(Bool.self, forKey: .isBackup)) ?? false
        isManualSaveBackup = (try? container.decode(Bool.self, forKey: .isManualSaveBackup)) ?? false
        isPeriodicBackup = (try? container.decode(Bool.self, forKey: .isPeriodicBackup)) ?? false
        interval = (try? container.decode(Int.self, forKey: .interval)) ?? SettingBackupMinute.zero.integer
    }
    
    func toStringJSON()  -> String {
        let dict = [
            "\(CodingKeys.isBackup.rawValue)": self.isBackup ?? false,
            "\(CodingKeys.isManualSaveBackup.rawValue)": self.isManualSaveBackup ?? false,
            "\(CodingKeys.isPeriodicBackup.rawValue)": self.isPeriodicBackup ?? false,
            "\(CodingKeys.interval.rawValue)": self.interval ?? SettingBackupMinute.zero.integer
        ] as [String : Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            if let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        return ""
    }
    
    init(isBackup: Bool, isManualSaveBackup: Bool, isPeriodicBackup: Bool, interval: Int) {
        self.isBackup = isBackup
        self.isManualSaveBackup = isManualSaveBackup
        self.isPeriodicBackup = isPeriodicBackup
        self.interval = interval
    }
    
    static let valueDefault = SettingBackupModel(
        isBackup: false ,
        isManualSaveBackup: false,
        isPeriodicBackup: false,
        interval: SettingBackupMinute.zero.integer)
    
}
