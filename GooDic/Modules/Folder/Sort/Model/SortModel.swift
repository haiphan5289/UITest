//
//  SortModel.swift
//  GooDic
//
//  Created by haiphan on 09/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

public struct SortModel: Codable {
    let sortName: ElementSort
    let asc: Bool
    let isActiveManual: Bool?
    
    func sendUserProperties() -> String {
        switch sortName {
        case .free:
            return ""
        case .manual:
            return "manual"
        case .updated_at:
            if asc {
                return "updated_at_asc"
            } else {
                return "updated_at_desc"
            }
        case .created_at:
            if asc {
                return "created_at_asc"
            } else {
                return "created_at_desc"
            }
        case .title:
            if asc {
                return "title_asc"
            } else {
                return "title_desc"
            }
        }
    }
    
    func getAsc() -> String {
        if self.asc {
            return "asc"
        } else {
            return "desc"
        }
    }
    
    static let valueDefault = SortModel(sortName: .created_at, asc: false, isActiveManual: false)
    static let valueDefaultDraft = SortModel(sortName: .updated_at, asc: false, isActiveManual: false)
}
