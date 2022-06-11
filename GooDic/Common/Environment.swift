//
//  Environment.swift
//  GooDic
//
//  Created by ttvu on 7/6/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

/// a middleware class helping to get configurate values
enum Environment {
    enum Keys: String {
        case webScheme = "WEB_SCHEME"
        case webHost = "WEB_HOST"
        case wvScheme = "WEBVIEW_SCHEME"
        case wvHost = "WEBVIEW_HOST"
        case wvFeedbackPath = "WEBVIEW_FEEDBACK_PATH"
        case wvDictPath = "WEBVIEW_DICT_PATH"
        case apiScheme = "API_SCHEME"
        case apiHost = "API_HOST"
        case apiThsrsPath = "API_THSRS_PATH"
        case apiIdiomPath = "API_IDIOM_PATH"
        case apiSuggestPath = "API_SUGGEST_PATH"
        case apiListDevice = "API_LIST_DEVICE"
        case apiDeleteDevice = "API_DELETE_DEVICE"
        case apiAddDevice = "API_ADD_DEVICE"
        case apiValidationServer = "API_VALIDATION_SERVER"
        case apiIOSDeviceName = "API_IOS_DEVICE_NAME"
        case apiGetDrafts = "API_GET_DRAFTS"
        case apiGetDraftDetail = "API_GET_DRAFT_DETAIL"
        case apiAddDraft = "API_ADD_DRAFT"
        case apiDeleteDraft = "API_DELETE_DRAFT"
        case apiMoveDrafts = "API_MOVE_DRAFTS"
        case apiGetFolders = "API_GET_FOLDERS"
        case apiAddFolder = "API_ADD_FOLDER"
        case apiDeleteFolder = "API_DELETE_FOLDER"
        case apiFoldersSort = "API_FOLDERS_SORT"
        case apiAccountInfo = "API_ACCOUNT_INFO"
        case apiVerifyReceipt = "API_VERIFY_RECEIPT"
        case apiBillingStatus = "API_BILLING_STATUS"
        case apiWebSettings = "API_WEB_SETTINGS"
        case apiRRHost = "API_RR_HOST"
        case subcriptionId = "SUBCRIPTION_ID"
        case apiSortDraftSetting = "API_DRAFT_SORT"
        case apiDraftSortManual = "API_DRAFT_SORT_MANUAL"
        case apiBackupCheck = "API_BACKUP_CHECK"
        case apiGetBackupDrafts =  "API_GET_BACKUP_DRAFTS"
        case apiGetBackupDraftDetail = "API_GET_BACKUP_DRAFT_DETAIL"
        case apiBackupDraftRestore = "API_BACKUP_DRAFT_RESTORE"
        case apiAddBackUp = "API_ADD_BACKUP"
    }
    
    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()
    
    static let apiIOSDeviceName: String = {
        value(fromKey: .apiIOSDeviceName)
    }()
    
    static let apiValidationServer: String = {
        value(fromKey: .apiValidationServer)
    }()
    
    static let apiAddDevice: String = {
        value(fromKey: .apiAddDevice)
    }()
    
    static let webScheme: String = {
        value(fromKey: .webScheme)
    }()
    
    static let webHost: String = {
        value(fromKey: .webHost)
    }()
    
    static let wvScheme: String = {
        value(fromKey: .wvScheme)
    }()
    
    static let wvHost: String = {
        value(fromKey: .wvHost)
    }()
    
    static let wvFeedbackPath: String = {
        value(fromKey: .wvFeedbackPath)
    }()
    
    static let wvDictPath: String = {
        value(fromKey: .wvDictPath)
    }()
    
    static let apiScheme: String = {
        value(fromKey: .apiScheme)
    }()
    
    static let apiHost: String = {
        value(fromKey: .apiHost)
    }()
    
    static let apiThsrsPath: String = {
        value(fromKey: .apiThsrsPath)
    }()
    
    static let apiIdiomPath: String = {
        value(fromKey: .apiIdiomPath)
    }()
    
    static let apiSuggestPath: String = {
        value(fromKey: .apiSuggestPath)
    }()
    
    static let apiListDevice: String = {
        value(fromKey: .apiListDevice)
    }()
    
    static let apiDeleteDevice: String = {
        value(fromKey: .apiDeleteDevice)
    }()
    
    static let apiGetDrafts: String = {
        value(fromKey: .apiGetDrafts)
    }()
    
    static let apiGetDraftDetail: String = {
        value(fromKey: .apiGetDraftDetail)
    }()
    
    static let apiAddDraft: String = {
        value(fromKey: .apiAddDraft)
    }()
    
    static let apiDeleteDraft: String = {
        value(fromKey: .apiDeleteDraft)
    }()
    
    static let apiMoveDrafts: String = {
        value(fromKey: .apiMoveDrafts)
    }()
    
    static let apiGetFolders: String = {
        value(fromKey: .apiGetFolders)
    }()
    
    static let apiAddFolder: String = {
        value(fromKey: .apiAddFolder)
    }()
    
    static let apiDeleteFolder: String = {
        value(fromKey: .apiDeleteFolder)
    }()
    
    static let apiFoldersSort: String = {
        value(fromKey: .apiFoldersSort)
    }()
    
    static let apiAccountInfo: String = {
        value(fromKey: .apiAccountInfo)
    }()
    
    static let apiVerifyReceipt: String = {
        value(fromKey: .apiVerifyReceipt)
    }()
    
    static let apiBillingStatus: String = {
        value(fromKey: .apiBillingStatus)
    }()
    
    static let apiDraftSortManual: String = {
        value(fromKey: .apiDraftSortManual)
    }()
    
    static let apiSortDraftSetting: String = {
        value(fromKey: .apiSortDraftSetting)
    }()
    
    static let apiWebSettings: String = {
        value(fromKey: .apiWebSettings)
    }()
    
    static let apiRRHost: String = {
        value(fromKey: .apiRRHost)
    }()
    
    static let subcriptionId: String = {
        value(fromKey: .subcriptionId)
    }()
    
    static let apiBackupCheck: String = {
        value(fromKey: .apiBackupCheck)
    }()
    static let apiGetBackupDrafts: String = {
        value(fromKey: .apiGetBackupDrafts)
    }()
    
    static let apiGetBackupDraftDetail: String = {
        value(fromKey: .apiGetBackupDraftDetail)
    }()
    
    static let apiBackupDraftRestore: String = {
        value(fromKey: .apiBackupDraftRestore)
    }()
    
    static let apiAddBackUp: String = {
        value(fromKey: .apiAddBackUp)
    }()
    
    static func value(fromKey key: Keys) -> String {
        guard let value = Environment.infoDictionary[key.rawValue] as? String else {
            fatalError("\(key.rawValue) not set in plist for this environment")
        }
        
        return value
    }
}
