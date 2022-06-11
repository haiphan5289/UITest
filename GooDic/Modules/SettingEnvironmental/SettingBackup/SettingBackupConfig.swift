//
//  SettingBackupConfig.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

enum SettingBackupAction {
    case isBackup
    case isManualSaveBackup
    case isPeriodicBackup
    case isSelectMinute
    case none
}

enum SettingBackupMinute: String {
    case zero, five, ten, fifteen

    var text: String {
        switch self {
        case .five: return "5"
        case .ten: return "10"
        case .fifteen: return "15"
        case .zero: return "0"
        }
    }
    var integer: Int {
        switch self {
        case .five: return 5
        case .ten: return 10
        case .fifteen: return 15
        case .zero: return 0
        }
    }
    
    static func getElement(text: String) -> Self {
        if text == five.text {
            return five
        }
        
        if text == ten.text {
            return ten
        }
        
        if text == fifteen.text {
            return fifteen
        }
        
        return zero
    }
}

struct SettingBackupData {
    var title: String
    var content: String
    var action: SettingBackupAction
    
    init(title: String, content: String, action: SettingBackupAction) {
        self.title = title
        self.content = content
        self.action = action
    }
}

enum SettingBackUpSectionCell: Int {
    case settingBackupData = 0 , settingBackupTitle, settingBackupRule, settingBackupMinute
}
