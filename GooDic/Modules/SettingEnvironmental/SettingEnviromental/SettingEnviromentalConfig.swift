//
//  SettingEnviromentalConfig.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

enum SettingEnviromentalAction {
    case openSettingBackup
    case none
}

struct SettingEnviromentalData {
    var title: String
    var sceneType: GATracking.Scene
    var action: SettingEnviromentalAction
    
    init(title: String, sceneType: GATracking.Scene, action: SettingEnviromentalAction) {
        self.title = title
        self.sceneType = sceneType
        self.action = action
    }
}
