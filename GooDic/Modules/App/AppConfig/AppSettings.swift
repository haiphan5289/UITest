//
//  AppSettings.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

enum AppSettings {
    @Storage(key: "agreementDate", defaultValue: Date(timeIntervalSince1970: 0))
    static var agreementDate: Date
    
    @Storage(key: "firstRun", defaultValue: true)
    static var firstRun: Bool
    
    @Storage(key: "guideUserToAddNewDocument", defaultValue: false)
    static var guideUserToAddNewDocument: Bool
    
    @Storage(key: "guideUserToSwipeDraft", defaultValue: false)
    static var guideUserToSwipeDraft: Bool
    
    @Storage(key: "guideUserToSwipeFolder", defaultValue: false)
    static var guideUserToSwipeFolder: Bool
    
    @Storage(key: "guideUserToEditMode", defaultValue: false)
    static var guideUserToEditMode: Bool
    
    @Storage(key: "guideUserToTrash", defaultValue: false)
    static var guideUserToTrash: Bool
    
    @Storage(key: "guideUserToCheckAPITutorial", defaultValue: false)
    static var guideUserToCheckAPITutorial: Bool
    
    @Storage(key: "fontStyleLevel", defaultValue: 2)
    static var fontStyleLevel: Int
    
    @Storage(key: "firstInstallBuildVersion", defaultValue: -1)
    static var firstInstallBuildVersion: Int
    
    @Storage(key: "firstLogin", defaultValue: true)
    static var firstLogin: Bool
    
    @Storage(key: "forceLogout", defaultValue: false)
    static var forceLogout: Bool
    
    @Storage(key: "userInfo", defaultValue: nil)
    static var userInfo: UserInfo?
    
    // the Banner Message is used to notify users to have to save their cloud draft before closing the editor
    @Storage(key: "hideBannerAutoSaveInCreation", defaultValue: false)
    static var hideBannerInCreation: Bool
    
    @Storage(key: "hideBannerInHomeCloudDrafts", defaultValue: false)
    static var hideBannerInHomeCloudDrafts: Bool
    
    @Storage(key: "hideBannerInCloudDrafts", defaultValue: false)
    static var hideBannerInCloudDrafts: Bool
    
    @Storage(key: "hideBannerInCloudFolders", defaultValue: false)
    static var hideBannerInCloudFolders: Bool
    
    @Storage(key: "hideBannerInSelectionCloudFolder", defaultValue: false)
    static var hideBannerInSelectionCloudFolder: Bool
    
    @Storage(key: "settingFont", defaultValue: nil)
    static var settingFont: SettingFont?
    
    @Storage(key: "settingSearch", defaultValue: nil)
    static var settingSearch: SettingSearch?
    
    @Storage(key: "billingInfo", defaultValue: nil)
    static var billingInfo: BillingInfo?
    
    @Storage(key: "firstInHome", defaultValue: true)
    static var firstInHome: Bool

    @Storage(key: "ToastMessageFixModel", defaultValue: ToastMessageFixModel.valueDefault)
    static var showToastMgs: ToastMessageFixModel

    @Storage(key: "expirationDateHomeBanner", defaultValue: Date(timeIntervalSince1970: 0))
    static var expirationDateHomeBanner: Date
    
    @Storage(key: "lastVersionNotiHomeBanner", defaultValue: 0)
    static var lastVersionNotiHomeBanner: Int
    
    @Storage(key: "isUserHasBeenCloseHomeBanner", defaultValue: false)
    static var isUserHasBeenCloseHomeBanner: Bool
    
    @Storage(key: "showToastMgsDictionary", defaultValue: ToastMessageFixModel.valueDefault)
    static var showToastMgsDictionary: ToastMessageFixModel
    
    @Storage(key: "SortModel", defaultValue: SortModel.valueDefault)
    static var sortModel: SortModel
    
    @Storage(key: "ManualIndex", defaultValue: [])
    static var manualIndex: [FolderDataSourceProxy.ManualIndex]
    
    @Storage(key: "isFirstLaunchGreaterThan128", defaultValue: true)
    static var isFirstLaunchGreaterThan128: Bool
    
    @Storage(key: "sortAtFolder", defaultValue: nil)
    static var sortAtFolder: String?
    
    @Storage(key: "SortModelDrafts", defaultValue: SortModel.valueDefaultDraft)
    static var sortModelDrafts: SortModel
    
    @Storage(key: "sortModelDraftsUncategorized", defaultValue: SortModel.valueDefaultDraft)
    static var sortModelDraftsUncategorized: SortModel
    
    @Storage(key: "DraftManualIndex", defaultValue: [])
    static var draftManualIndex: [FolderDataSourceProxy.ManualIndex]
    
    @Storage(key: "DraftManualIndexUncategorized", defaultValue: [])
    static var draftManualIndexUncategorized: [FolderDataSourceProxy.ManualIndex]
    
    @Storage(key: "hasSortManualUncategorized", defaultValue: false)
    static var hasSortManualUncategorized: Bool
    
    @Storage(key: "hasSortManualHomeDrafts", defaultValue: false)
    static var hasSortManualHomeDrafts: Bool
    
    @Storage(key: "hasSortManualFolder", defaultValue: false)
    static var hasSortManualFolder: Bool
    
    @Storage(key: "SettingBackupModel", defaultValue: SettingBackupModel.valueDefault)
    static var settingBackupModel: SettingBackupModel
    
    @Storage(key: "FirstEnableSettingBackup", defaultValue: true)
    static var firstEnableSettingBackup: Bool
}
