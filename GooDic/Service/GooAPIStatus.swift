//
//  GooAPIStatus.swift
//  GooDic
//
//  Created by ttvu on 12/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

enum GooAPIStatus: String, CaseIterable {
    case normal = "00"
    case maintenance = "01"
    case maintenanceCannotUpdate = "02"
    case terminalRegistration = "10"
    case draftNotFound = "11"
    case folderNotFound = "12"
    case fullDevices = "20"
    case limitRegistrtion = "21"
    case executionError = "22"
    case duplicateFolder = "23"
    case exclusiveError = "24"
    case exclusiveDraftError = "25"
    case sessionTimeOut = "91"
    case authenticationError = "92"
    case receiptInvalid = "93"
    case otherError = "99"
    
    var value: Int {
        return Int(self.rawValue) ?? 0
    }
    
    func getError(data: Any? = nil, errorMessage: String? = nil) -> GooServiceError? {
        switch self {
        case .normal: return nil
        case .maintenance: return .maintenance("")
        case .maintenanceCannotUpdate: return .maintenanceCannotUpdate(data ?? "")
        case .terminalRegistration: return .terminalRegistration
        case .draftNotFound: return .draftNotFound
        case .folderNotFound: return .folderNotFound
        case .fullDevices: return .fullDevices
        case .limitRegistrtion: return .limitRegistrtion
        case .executionError: return .executionError
        case .duplicateFolder: return .duplicateFolder
        case .exclusiveError: return .exclusiveError
        case .exclusiveDraftError: return .exclusiveDraftError
        case .sessionTimeOut: return .sessionTimeOut
        case .authenticationError: return .authenticationError
        case .receiptInvalid: return .receiptInvalid
        case .otherError: return .otherError(errorMessage ?? "")
        }
    }
}
