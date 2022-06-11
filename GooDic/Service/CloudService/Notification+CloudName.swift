//
//  Notification+CloudName.swift
//  GooDic
//
//  Created by ttvu on 1/7/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let didUpdateCloudFolder = Notification.Name("didUpdateCloudFolder")

    // Add, Edit, Move, Delete
    // userInfo[folder_ids] = "ID,ID,ID..."
    static let didUpdateCloudDrafts = Notification.Name("didUpdateCloudDrafts")
}
