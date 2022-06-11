//
//  CloudService.swift
//  GooDic
//
//  Created by ttvu on 11/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public enum CloudDraftQuery {
    case all
    case uncategoried
    case folderId(String)
}

public protocol CloudGatewayProtocol {
    func getRegisteredDevices() -> Observable<[DeviceInfo]>
    func deleteDevice(deviceId: String) -> Observable<Void>
    func addDevice(name: String) -> Observable<Void>
    func getDeviceName(deviceCode: String) -> Observable<String>
    
    func getDraftList(query: CloudDraftQuery, offset: Int, limit: Int, sort: SortModel) -> Observable<PagingInfo<CloudDocument>>
    func getDraftDetail(_ draft: CloudDocument) -> Observable<CloudDocument>
    func addDraft(_ draft: CloudDocument) -> Observable<Date>
    func updateDraft(_ draft: CloudDocument, overwrite: Bool, reuseLastUpdate: Bool) -> Observable<Date>
    func deleteDrafts(draftIds: [String]) -> Observable<Void>
    func moveDrafts(draftIds: [String], to folderId: String) -> Observable<Void>
    
    func getFolderList(offset: Int, limit: Int, sortMode: SortModel?) -> Observable<PagingInfo<CloudFolder>>
    func addOrUpdateFolder(_ folderId: String, name: String) -> Observable<Void>
    func deleteFolder(_ id: String) -> Observable<Void>
    
    func getAccountInfo() -> Observable<String>
    func getAPIStatus() -> Observable<Void>
    func getCookieInfo() -> Observable<GooResponse<CookieInfo>>
    
    func sendReceiptInfo(productId: String) -> Observable<Void>
    func getBillingStatus() -> Observable<GooResponseBillingInfo>
    func getWebSettings(settingKey: String) -> Observable<String>
    func postWebSetiings(sortMode: SortModel, settingKey: String) -> Observable<Void>
    func sortFolders(folders: [Folder], sortedAt: String) -> Observable<Void>
    func postDraftSetiings(sortMode: SortModel, settingKey: String, folderId: String) -> Observable<Void>
    func getDraftSettings(settingKey: String, folderId: String) -> Observable<String>
    func sortDrafts(drafts: [Document], sortedAt: String, folderId: String) -> Observable<Void>
    func postBackupSettings(settingBackupModel: SettingBackupModel, settingKey: String) -> Observable<Void>
    func getBackupSettings(settingKey: String) -> Observable<SettingBackupModel?>
    func backupCheck(drafts: [Document]) -> Observable<Bool>
    func getBackupDraftList(document: Document) -> Observable<[CloudBackupDocument]>
    func getBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument) -> Observable<CloudBackupDocument>
    func backupDraftRestore(document: Document, backupDocument: CloudBackupDocument) -> Observable<Void>
    func addBackUp(draft: Document) -> Observable<Void>
}

public typealias CloudService = GooService<CloudGatewayProtocol>
