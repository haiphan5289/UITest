//
//  TrackingConstant.swift
//  GooDic
//
//  Created by ttvu on 6/17/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import UIKit
import AppsFlyerLib

/// tracking helper method used to send events to Google Analytics
enum GATracking {
    enum LoginStatus: String {
        case login = "login"
        case logout = "logout"
    }
    
    enum UserStatus: String {
        case premium = "premium"
        case regular = "regular"
        case other = "other"
    }
    
    enum UserStatus2: String {
        case premium = "paid"
        case regular = "free"
        case other = "nologin"
    }
    
    enum GooLoginType: String {
        case login = "login"
        case logout = "nologin"
    }
    
    enum SearchCondition: String {
        case prefixMatch = "prefix_match"
        case perfectMatch = "perfect_match"
        case backwardMatch = "backward_match"
        case partialMatch = "partial_match"
        case explanatoryText = "explanatory_text"
    }
    
    enum ExecSearchKind: String {
        case suggestedWord = "suggested_word"
        case inputWord = "input_word"
    }
    
    enum InAppPurchare: String {
        case AppStorePromotion = "AppStorePromotion"
    }
    
    enum Param {
        case loginStatus(LoginStatus)
        case screenName(String)
        case draftsInLocalCount(Int)
        case draftsInCloudCount(Int)
        case foldersInLocalCount(Int)
        case foldersInCloudCount(Int)
        case deviceRegisterCount(Int)
        case characterCount([Int])
        case displayMode(UIUserInterfaceStyle)
        case userStatus(UserStatus)
        case font(String)
        case fontSize(String)
        case save(Int) // ON: 0 ; OFF: 1
        case word(String)
        case searchCondition(SearchCondition)
        case searchKind(ExecSearchKind)
        case sortOrder(SortModel)
        
        var key: String {
            switch self {
            case .loginStatus: return "login_status"
            case .screenName: return "screen_name"
            case .draftsInLocalCount: return "drafts_in_local_count"
            case .draftsInCloudCount: return "drafts_in_cloud_count"
            case .foldersInLocalCount: return "folders_in_local_count"
            case .foldersInCloudCount: return "folders_in_cloud_count"
            case .deviceRegisterCount: return "device_register_count"
            case .characterCount: return "character_count"
            case .displayMode: return "mode"
            case .userStatus: return "user_status"
            case .font: return "font"
            case .fontSize: return "fontsize"
            case .save: return "save"
            case .word: return "word"
            case .searchCondition: return "search_conditions"
            case .searchKind: return "kind"
            case .sortOrder: return "sort_order"
            }
        }
        
        var value: String {
            switch self {
            case .loginStatus(let status): return status.rawValue
            case .screenName(let name): return name
            case .draftsInLocalCount(let count): return "\(count)"
            case .draftsInCloudCount(let count): return "\(count)"
            case .foldersInLocalCount(let count): return "\(count)"
            case .foldersInCloudCount(let count): return "\(count)"
            case .deviceRegisterCount(let count): return "\(count)"
            case .characterCount(let numbers):
                let listStr = numbers.map({ "\($0)" })
                return listStr.joined(separator: ",")
            case .displayMode(let mode): return mode == .dark ? L10n.Tracking.DisplayMode.dark : L10n.Tracking.DisplayMode.light
            case .userStatus(let status): return status.rawValue
            case .font(let font): return font
            case .fontSize(let size): return size
            case .save(let isOn): return  "\(isOn)"
            case .word(let word): return word
            case .searchCondition(let condition): return condition.rawValue
            case .searchKind(let kind): return kind.rawValue
            case .sortOrder(let sort): return sort.sendUserProperties()
            }
        }
    }
    
    static func map<T>(_ scene: Scene, class: T) {
        let screenClass = String(describing: T.self)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: scene.rawValue,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    static func scene(_ event: Scene) {
        scene(event, params: nil)
    }
    
    static func scene(_ event: Scene, params: [Param]?) {
        let parameters = params?.map({[$0.key, $0.value]})
            .reduce(into: [String:String]()) { (result, value) in
                result[value[0]] = value[1]
            }
        
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

    
    static func tap(_ event: Tap) {
        tap(event, params: nil)
    }
    
    static func tap(_ event: Tap, params: [Param]?) {
        let parameters = params?.map({[$0.key, $0.value]})
            .reduce(into: [String:String]()) { (result, value) in
                result[value[0]] = value[1]
            }
        
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }
    
    static func check(_ event: Check, params: [Param]?) {
        let parameters = params?.map({[$0.key, $0.value]})
            .reduce(into: [String:String]()) { (result, value) in
                result[value[0]] = value[1]
            }
        
        Analytics.logEvent(event.rawValue, parameters: parameters)
    }
    
    static func send(characterNumberOfDrafts list: [Int]) {
        if list.isEmpty {
            return
        }
        
        let listStr = list.map({ "\($0)" })
        let value = listStr.joined(separator: ",")
        
        let eventName = "checkCharacterNumberOfDraft"
        let eventParams = [
            "character_count": value // 12,232,43,800
        ]
        
        Analytics.logEvent(eventName, parameters: eventParams)
    }
    
    static func sendUserProperties(property: UserProperties) {
        Analytics.setUserProperty(property.value, forName: property.key)
    }
    
    static func sendEventAppStorePromotion() {
        Analytics.logEvent(InAppPurchare.AppStorePromotion.rawValue, parameters: nil)
    }
    
    static func sendAFEventPurchase(values: [String:Any]?) {
            AppsFlyerLib.shared().logEvent(name: AFEventPurchase,
                                           values: values, completionHandler: { (response: [String : Any]?, error: Error?) in
             if let response = response {
                 
             }
             if let error = error {
                 
             }
        })
    }
    
    static func sendAFEventLoginSuccess() {
        AppsFlyerLib.shared().logEvent(AFEventLogin, withValues: nil);
    }
    
    static func sendUserPropertiesAfterLogin(userIdForGA: String?) {
        if var stringId = userIdForGA {
            if stringId.count > 36 {
                stringId = stringId.substring(to: 36)
            }
            let userIdForGA: UserProperties = .userIdForGA(stringId)
            GATracking.sendUserProperties(property: userIdForGA)
        }
        
        let userStatus: UserProperties = AppSettings.billingInfo?.billingStatus == .free
            ? .userStatus2(.regular)
            : .userStatus2(.premium)
        GATracking.sendUserProperties(property: userStatus)
        
        let gooLoginType: UserProperties = .gooLoginType(.login)
        GATracking.sendUserProperties(property: gooLoginType)
    }
    
    static func sendUserPropertiesAfterLogout() {
        let userStatus: UserProperties = .userStatus2(.other)
        GATracking.sendUserProperties(property: userStatus)
        
        let gooLoginType: UserProperties = .gooLoginType(.logout)
        GATracking.sendUserProperties(property: gooLoginType)
    }
    
    enum Scene: String {
        case unknown = "Base" // base view controller, default
        case agreement = "Agreement"
        case reAgreement = "ReAgreement"
        case tutorial = "Tutorial"
        case trash = "Trash"
        case create = "Create"
        case paraphrase = "Paraphrase" // thesaurus
        case proofread = "Proofread" // idiom
        case searchInDraft = "SearchInDraft"
        case searchResultslnDraft = "SearchResultsInDraft"
        case feedback = "Feedback"
        case search = "Search"
        case searchResults = "SearchResults"
        case menu = "Menu"
        case info = "Info"
        case help = "Help"
        case terms = "Terms"
        case appPolicy = "AppPolicy"
        case privacyPolicy = "PrivacyPolicy"
        case personalDataPolicy = "PersonalDataPolicy"
        case openLicense = "OpenLicense"
        case selectDestinationFolder = "SelectDestinationFolder"
        case draftsInFolder = "DraftsInFolder"
        case folder = "Folder"
        case openLoginScreen = "OpenLoginScreen"
        case openRegisterDeviceScreen = "OpenRegisterDeviceScreen"
        case openForceLogoutScreen = "OpenForceLogoutScreen"
        case openHomeScreen = "OpenHomeScreen"
        case requestPremium = "PremiumService"
        case confirmPremium = "RegistrationPlanConfirmation"
        case accountInfo = "AccountInformation"
        case cancelSubcription = "PremiumUnregister"
        case settingsAndSharing = "SettingsAndSharing"
        case sentenceSearch = "SentenceSearch"
        case searchOptions = "SearchOptions"
        case law = "Law"
        case sort = "Sort"
        case twitter = "Twitter"
        
        case otherWebView = "OtherWebView"
        case reference = "Reference"
        
        case billingAppeal2 = "BillingAppeal2"
        case billingAppeal = "BillingAppeal"
        case backup = "Backup"
        case settingEnviromental = "SettingEnviromental"
        case setting = "Setting"
        case settingBackup = "SettingBackup"
        case backupList = "BackupList"
        case backupDetail = "BackupDetail"
    }
    
    enum Tap: String {
        case tapCreateDraft = "tapCreateDraft"
        case tapRemoveDraft = "tapRemoveDraft"
        case tapParaphrase = "tapParaphrase"
        case tapParaphraseWord = "tapParaphraseWord"
        case tapSearchWordToParaphrase = "tapSearchWordToParaphrase"
        case tapProofread = "tapProofread"
        case tapProofreadWord = "tapProofreadWord"
        case tapSearchWordToProofread = "tapSearchWordToProofread"
        case tapShareDraft = "tapShareDraft"
        case tapHandle = "tapHandle"
        case tapRedo = "tapRedo"
        case tapUndo = "tapUndo"
        case tapShareService = "tapShareService"
        case tapSave = "tapSave"
        case tapChangeTextSize = "tapChangeTextSize"
        case tapMoveToFolder = "tapMoveToFolder"
        case tapSelectFolderToMoveTo = "tapSelectFolderToMoveTo"
        case tapCreateNewFolder = "tapCreateNewFolder"
        case tapChangeFolderName = "tapChangeFolderName"
        case tapRemoveFolder = "tapRemoveFolder"
        case tapSignUp = "tapSignUp"
        case tapLogin = "tapLogin"
        case tapLogout = "tapLogout"
        case tapRegisterDevice = "tapRegisterDevice"
        case tapCloudTabHomeScreen = "tapCloudTabHomeScreen"
        case tapLocalTabHomeScreen = "tapLocalTabHomeScreen"
        case tapLocalTabFolderScreen = "tapLocalTabFolderScreen"
        case tapCloudTabFolderScreen = "tapCloudTabFolderScreen"
        case tapCheckboxUpToCloud = "tapCheckboxUpToCloud"
        case tapEdit = "tapEdit"
        case tapSearchIconInHeader = "tapSearchIconInHeader"
        case tapMenuIconInHeader = "tapMenuIconInHeader"
        case tapSearchOptions = "tapSearchOptions"
        case tapFind = "tapFind"
        case tapFindAndReplace = "tapFindAndReplace"
        case tapViewPremium = "tapViewPremium"
        case tapViewPremiumInMenu = "tapViewPremiumInMenu"
        case tapRegisterForPremium = "tapRegisterForPremium"
        case tapRestorePreviousPurchase = "tapRestorePreviousPurchase"
        case tapRegister = "tapRegister"
        case tapIosUnregister = "tapIosUnregister"
        case tapAndroidUnregister = "tapAndroidUnregister"
        case tapGooStorePcUnregister = "tapGooStorePcUnregister"
        case tapLocalTabInDraft = "tapLocalTabInDraft"
        case tapCloudTabInDraft = "tapCloudTabInDraft"
        case settingFont = "settingFont"
        case tapSharePcUrl = "tapSharePcUrl"
        case searchResultsInPremiumInfoDraft = "SearchResultsInPremiumInfoDraft"
        case searchResultsInPremiumInfoDraftClose = "SearchResultsInPremiumInfoDraftClose"
        case searchResultsInPremiumInfo = "SearchResultsInPremiumInfo"
        case searchResultsInPremiumInfoClose = "SearchResultsInPremiumInfoClose"
        case tapSettingSave = "tapSettingSave"
        case tapOriginalInfo = "tapOriginalInfo"
        case tapOriginalInfoClose = "tapOriginalInfoClose"
        case tapLoginForPremium = "tapLoginForPremium"
        case tapLoginForPremiumClose = "tapLoginForPremiumClose"
        case execSearchInDraft = "ExecSearchInDraft"
        case execSearch = "ExecSearch"
        case searchConditionsInPremiumInfoDraft = "SearchConditionsInPremiumInfoDraft"
        case searchConditionsInPremiumInfoDraftClose = "SearchConditionsInPremiumInfoDraftClose"
        case searchConditionsInPremiumInfo = "SearchConditionsInPremiumInfo"
        case searchConditionsInPremiumInfoClose = "SearchConditionsInPremiumInfoClose"
        case tapForcedUpdate = "tapForcedUpdate"
        case tapFolderSortMenu = "tapFolderSortMenu"
        case tapFolderSortOrderTitle = "tapFolderSortOrderTitle"
        case tapFolderSortOrderCreatedAt = "tapFolderSortOrderCreatedAt"
        case tapFolderSortOrderUpdatedAt = "tapFolderSortOrderUpdatedAt"
        case tapFolderSortOrderManual = "tapFolderSortOrderManual"
        case tapFolderSortOrderClose = "tapFolderSortOrderClose"
        case tapFolderSortOrderManualFree = "tapFolderSortOrderManualFree"
        case tapViewPremiumInFolderSortOrder = "tapViewPremiumInFolderSortOrder"
        case tapFolderSortOrder = "tapFolderSortOrder"
        case tapCloudFolderSortMenu = "tapCloudFolderSortMenu"
        case tapCloudFolderSortOrderTitle = "tapCloudFolderSortOrderTitle"
        case tapCloudFolderSortOrderCreatedAt = "tapCloudFolderSortOrderCreatedAt"
        case tapCloudFolderSortOrderUpdateAt = "tapCloudFolderSortOrderUpdatedAt"
        case tapCloudFolderSortOrderManual = "tapCloudFolderSortOrderManual"
        case tapCloudFolderSortOrderClose = "tapCloudFolderSortOrderClose"
        case tapCloudFolderSortOrderManualFree = "tapCloudFolderSortOrderManualFree"
        case tapViewPremiumInCloudFolderSortOrder = "tapViewPremiumInCloudFolderSortOrder"
        case tapCloudFolderSortOrder = "tapCloudFolderSortOrder"
        case tapCharacterSelectionSearch = "tapCharacterSelectionSearch"
        case tapTwitter = "tapTwitter"
        case tapDraftSortMenu = "tapDraftSortMenu"
        case tapDraftSortOrderManualFree = "tapDraftSortOrderManualFree"
        case tapViewPremiumInDraftSortOrder = "tapViewPremiumInDraftSortOrder"
        case tapDraftSortOrderTitle = "tapDraftSortOrderTitle"
        case tapDraftSortOrderUpdatedAt = "tapDraftSortOrderUpdatedAt"
        case tapDraftSortOrderManual = "tapDraftSortOrderManual"
        case tapDraftSortOrder = "tapDraftSortOrder"
        case tapDraftSortOrderClose = "tapDraftSortOrderClose"
        case tapCloudDraftSortMenu = "tapCloudDraftSortMenu"
        case tapCloudDraftSortOrderManualFree = "tapCloudDraftSortOrderManualFree"
        case tapViewPremiumInCloudDraftSortOrder = "tapViewPremiumInCloudDraftSortOrder"
        case tapCloudDraftSortOrderTitle = "tapCloudDraftSortOrderTitle"
        case tapCloudDraftSortOrderUpdatedAt = "tapCloudDraftSortOrderUpdatedAt"
        case tapCloudDraftSortOrderManual = "tapCloudDraftSortOrderManual"
        case tapCloudDraftSortOrder = "tapCloudDraftSortOrder"
        case tapCloudDraftSortOrderClose = "tapCloudDraftSortOrderClose"
    }
    
    enum Check: String {
        case checkCharacterNumberOfDraft = "checkCharacterNumberOfDraft"
        case displayMode = "displayMode"
    }
    
    enum UserProperties {
        case userStatus2(UserStatus2)
        case gooLoginType(GooLoginType)
        case userIdForGA(String?)
        case folderSortOrder(SortModel)
        case cloudFolderSortOrder(SortModel)
        case draftSortOrder(SortModel)
        case draftSortOrderFolder(SortModel)
        case cloudDraftSortOrder(SortModel)
        case cloudDraftSortOrderFolder(SortModel)
        
        var key: String {
            switch self {
            case .userStatus2: return "user_status2"
            case .gooLoginType: return "goo_login_type"
            case .userIdForGA: return "user_id_for_ga"
            case .folderSortOrder: return "folder_sort_order"
            case .cloudFolderSortOrder: return "cloud_folder_sort_order"
            case .draftSortOrder: return "draft_sort_order_all"
            case .draftSortOrderFolder: return "draft_sort_order_folder"
            case .cloudDraftSortOrder: return "cloud_draft_sort_all"
            case .cloudDraftSortOrderFolder: return "cloud_draft_sort_folder"
            }
        }
        
        var value: String? {
            switch self {
            case .userStatus2(let status): return status.rawValue
            case .gooLoginType(let type): return type.rawValue
            case .userIdForGA(let idGA): return idGA
            case .folderSortOrder(let sort): return sort.sendUserProperties()
            case .cloudFolderSortOrder(let sort): return sort.sendUserProperties()
            case .draftSortOrder(let sort): return sort.sendUserProperties()
            case .cloudDraftSortOrder(let sort): return sort.sendUserProperties()
            case .draftSortOrderFolder(let sort): return sort.sendUserProperties()
            case .cloudDraftSortOrderFolder(let sort): return sort.sendUserProperties()
            }
        }
    }
}
