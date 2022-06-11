//
//  GooServices.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public enum GooServiceError: Error {
    case badURL // self-definition
    case parseError // self-definition
    case emptyData // self-definition

    case maintenance(String)
    case maintenanceCannotUpdate(Any)
    case terminalRegistration
    case draftNotFound
    case fullDevices
    case folderNotFound
    case backupNotFound
    case limitRegistrtion
    case executionError
    case duplicateFolder
    case exclusiveError
    case exclusiveDraftError
    case sessionTimeOut
    case authenticationError
    case receiptInvalid
    case otherError(String)
    case errorHttpStatus(String)
    case receiptEmpty
    
    var code: Int {
        switch self {
        case .badURL: return 9000
        case .parseError: return 9001
        case .emptyData: return 9002
            
        case .maintenance: return 1
        case .maintenanceCannotUpdate: return 2
        case .terminalRegistration: return 10
        case .draftNotFound: return 11
        case .folderNotFound: return 12
        case .backupNotFound: return 13
        case .fullDevices: return 20
        case .limitRegistrtion: return 21
        case .executionError: return 22
        case .duplicateFolder: return 23
        case .exclusiveError: return 24
        case .exclusiveDraftError: return 25
        case .sessionTimeOut: return 91
        case .authenticationError: return 92
        case .otherError: return 99
        case .receiptInvalid: return 93
        case .errorHttpStatus: return 400
        case .receiptEmpty: return 900
        }
    }
    
    var description: String {
        switch self {
        case .maintenance:
            return L10n.Server.Error.Title.maintenance
        case .maintenanceCannotUpdate:
            return L10n.Server.Error.Title.maintenanceCannotUpdate
        case .terminalRegistration:
            return L10n.Server.Error.Title.terminalRegistration
        case .draftNotFound:
            return L10n.Server.Error.Title.draftNotFound
        case .folderNotFound:
            return L10n.Server.Error.Title.folderNotFound
        case .backupNotFound:
            return L10n.Server.Error.Title.backupNotFound
        case .limitRegistrtion:
            return L10n.Server.Error.Title.limitDraftRegistrtion
        case .executionError:
            return L10n.Server.Error.Title.executionError
        case .duplicateFolder:
            return L10n.Server.Error.Title.duplicateFolder
        case .sessionTimeOut:
            return L10n.Server.Error.Title.sessionTimeOut
        case .authenticationError:
            return L10n.Server.Error.Title.authenticationError
        case .otherError:
            return L10n.Server.Error.Title.otherError
        case .receiptInvalid:
            return L10n.Premium.Receipt.invalid
        case .receiptEmpty:
            return L10n.userHaveNotEverBeenPurchase
        default: return ""
        }
    }
    
    var title: String { // yoyo
        return "will be removed soon"
    }
    
    var detail: String { // yoyo
        return "will be removed soon"
    }
}

public protocol GooServiceProtocol { }

public class GooService<T>: GooServiceProtocol {
    public let gateway: T
    
    public init(gateway: T) {
        self.gateway = gateway
    }
}

public class GooServices {
    
    public static let shared = GooServices()
    private init() {}
    
    var factoryDict: [String: ()->GooServiceProtocol] = [:]
    
    public func add<T: GooServiceProtocol>(_ factory: @escaping ()->T) {
        factoryDict[String(describing: T.self)] = factory
    }
    
    public func resolve<T: GooServiceProtocol>(_ type: T.Type) -> T {
        factoryDict[String(describing: T.self)]?() as! T
    }
}
