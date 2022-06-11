//
//  FileStoreForceUpdate.swift
//  GooDic
//
//  Created by Vinh Nguyen on 24/11/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

public struct FileStoreForceUpdate: Codable {
    let enabled: Bool?
    let messageButtonText: String?
    let messageText: String?
    let messageTitle: String?
    let startDateTime: Date?
    let targetVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case messageButtonText = "message_button_text"
        case messageText = "message_text"
        case messageTitle = "message_title"
        case startDateTime = "start_datetime"
        case targetVersion = "target_version"
    }
    
    func isForceUpdate() -> Bool {
        var isForceUpdate = false
        if let isEnable = self.enabled, isEnable {
            if let date = self.startDateTime, date <= Date() {
//                if let currentVersion = AppManager.shared.getCurrentVersionApp(), let targetVersion = self.targetVersion   {
//                    switch currentVersion.applicationVersionCompare(targetVersion) {
//                    case .orderedDescending, .orderedSame: break
//                    case .orderedAscending:
//                        isForceUpdate = true
//                        break
//                    default:
//                        break
//                    }                    
//                }
            }
        }
        return isForceUpdate
    }
}
