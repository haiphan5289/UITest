//
//  CloudFolder.swift
//  GooDic
//
//  Created by ttvu on 11/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct CloudFolder: Codable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "folder_id"
        case name = "folder_name"
    }
}

extension CloudFolder {
    var folder: Folder {
        return Folder(name: self.name, id: .cloud(self.id), manualIndex: nil, hasSortManual: false)
    }
}
