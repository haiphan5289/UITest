//
//  CloudMockDataGateway.swift
//  GooDic
//
//  Created by ttvu on 11/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public struct CloudMockDataGateway: CloudGatewayProtocol {
    public func getBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument) -> Observable<CloudBackupDocument> {
        let rawData =
        """
        {
          "status": "\(GooAPIStatus.normal.rawValue)",
          "title": "タイトル",
          "text": "ｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘ",
          "last_update": "202011191415",
          "device": "iPhone 7 plus"
        }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .map({ (data) -> GooResponseBackupDraftDetail in
                let result = try autoreleasepool(invoking: { () -> GooResponseBackupDraftDetail in
                    return try JSONDecoder().decode(GooResponseBackupDraftDetail.self, from: data)
                })
                return result
            })
            .flatMap({ (response) -> Observable<CloudBackupDocument> in
                let item = CloudBackupDocument(id: "", title: response.title, content: response.content, updatedAt: response.updatedAt, device: response.device, cursorPosition: response.cursorPosition)
                if response.status == .normal {
                    return Observable.just(item)
                }
                return Observable.error(response.status.getError(data: item)!)
            })
    }
    
    public func getBackupDraftList(document: Document) -> Observable<[CloudBackupDocument]> {

        let rawData =
        """
        {
          "status": "\(GooAPIStatus.normal.rawValue)",
          "backups": [
                {
                  "id": "cf731126-8d9b-44ff-be7a-56a294c8c4e2",
                  "title": "タイトル",
                  "text": "ｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘ",
                  "last_update": "202011191415",
                  "device": "iPhone 7 plus"
                }
            ]
        }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .map({ (data) -> GooResponseBackupDraftList in
                let result = try autoreleasepool(invoking: { () -> GooResponseBackupDraftList in
                    return try JSONDecoder().decode(GooResponseBackupDraftList.self, from: data)
                })
                return result
            })
            .flatMap({ (response) -> Observable<[CloudBackupDocument]> in
                if response.status == .normal {
                    return Observable.just(response.data)
                }
                return Observable.error(response.status.getError(data: response.data)!)
            })
    }
    
    
    public func addBackUp(draft: Document) -> Observable<Void> {
        Observable.just(())
    }
    
    public func backupCheck(drafts: [Document]) -> Observable<Bool> {
        Observable.just(false)
    }
    
    public func sortDrafts(drafts: [Document], sortedAt: String, folderId: String) -> Observable<Void> {
        Observable.just(())
    }
    
    public func sortFolders(folders: [Folder], sortedAt: String) -> Observable<Void>   {
        Observable.just(())
    }
    
    public func postDraftSetiings(sortMode: SortModel, settingKey: String, folderId: String) -> Observable<Void> {
        Observable.just(())
    }
    
    public func getDraftSettings(settingKey: String, folderId: String) -> Observable<String> {
        Observable.just("")
    }
    
    public func postWebSetiings(sortMode: SortModel, settingKey: String) -> Observable<Void> {
        Observable.just(())
    }
    
    public func getWebSettings(settingKey: String) -> Observable<String> {
        Observable.just("")
    }
    
    public func postBackupSettings(settingBackupModel: SettingBackupModel, settingKey: String) -> Observable<Void> {
        Observable.just(())
    }
    
    public func getBackupSettings(settingKey: String) -> Observable<SettingBackupModel?> {
        Observable.just(nil)
    }
    
    public func getRegisteredDevices() -> Observable<[DeviceInfo]> {
        let rawData =
        """
        {
          "status": "00",
          "devices": [
            {
              "id": "3K0XXXXX-83XX-HEXX-KIXX-29KH83XXXXXX",
              "name": "iPhone 11 Pro",
              "regist_date": "20201119"
            }
          ]
        }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .map({ (data) -> GooResponseDevices in
                let result = try autoreleasepool(invoking: { () -> GooResponseDevices in
                    return try JSONDecoder().decode(GooResponseDevices.self, from: data)
                })
                
                return result
            })
            .flatMap { (response) -> Observable<[DeviceInfo]> in
                if response.status == .normal {
                    return Observable.just(response.data)
                }
                
                return Observable.error(response.status.getError(data: response.data)!)
            }
    }
    
    public func deleteDevice(deviceId: String) -> Observable<Void> {
        Observable.just(())
    }
    
    public func addDevice(name: String) -> Observable<Void> {
        Observable.just(())
    }
    
    public func getDeviceName(deviceCode: String) -> Observable<String> {
        Observable.just("Device name")
    }
    
    public func getDraftList(query: CloudDraftQuery, offset: Int, limit: Int, sort: SortModel) -> Observable<PagingInfo<CloudDocument>> {
        let total = 11
        func genDocData(number: Int) -> String {
            """
            {
              "id": "A2XXC4F9-0XX2-44D7-A624-415XXX5E62\(String(format: "%2d", number))",
              "title": "\(number)タイトル",
              "text": "\(number)ｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘ",
              "last_update": "202011191415",
              "folder_id": "F5SXC4F9-0FX2-45D7-A624-436XXX5EXXGH"
            }
            """
        }
        
        let maxOffset = max(offset, min(offset + limit, total))
        let documents: [String] = (offset..<maxOffset).map({ genDocData(number: $0) })
        
        
        let rawData =
        """
        {
          "status": "\(GooAPIStatus.maintenanceCannotUpdate.rawValue)",
          "total": \(total),
          "offset": \(offset),
          "limit": \(limit),
          "documents": [ \(documents.joined(separator: ",")) ]
        }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .map({ (data) -> GooResponseDocuments in
                let result = try autoreleasepool(invoking: { () -> GooResponseDocuments in
                    return try JSONDecoder().decode(GooResponseDocuments.self, from: data)
                })
                return result
            })
            .flatMap({ (response) -> Observable<PagingInfo<CloudDocument>> in
                let pagingInfo = PagingInfo(offset: response.offset,
                                            limit: response.limit,
                                            totalItems: response.total,
                                            hasMorePages: response.data.count == response.limit,
                                            items: response.data,
                                            name: response.folderName)
                
                if response.status == .normal {
                    return Observable.just(pagingInfo)
                }
                
                return Observable.error(response.status.getError(data: pagingInfo)!)
            })
    }
    
    public func getDraftDetail(_ draft: CloudDocument) -> Observable<CloudDocument> {
        let rawData =
        """
        {
          "status": \"\(GooAPIStatus.maintenanceCannotUpdate.rawValue)\",
          "document_title": "タイトル",
          "document_text": "ｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘｘ",
          "document_last_update": "20201119141500"
        }
        """
        
//        let rawData =
//        """
//        {
//          "status": \"\(GooAPIStatus.maintenance.rawValue)\"
//        }
//        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ (data) -> GooResponseDocumentDetail in
                let result = try autoreleasepool(invoking: { () -> GooResponseDocumentDetail in
                    return try JSONDecoder().decode(GooResponseDocumentDetail.self, from: data)
                })
                return result
            })
            .flatMap({ response -> Observable<CloudDocument> in
                let item = CloudDocument(id: draft.id,
                                         title: response.title,
                                         content: response.text,
                                         updatedAt: response.update,
                                         folderId: draft.folderId,
                                         folderName: draft.folderName,
                                         cursorPosition: draft.cursorPosition,
                                         manualIndex: nil)
                
                if response.status == .normal {
                    return Observable.just(item)
                }
                
                return Observable.error(response.status.getError(data: item)!)
            })
    }
    
    public func addDraft(_ draft: CloudDocument) -> Observable<Date> {
        return Observable
            .just(Date())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func updateDraft(_ draft: CloudDocument, overwrite: Bool, reuseLastUpdate: Bool) -> Observable<Date> {
        return Observable
            .just(Date())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func deleteDrafts(draftIds: [String]) -> Observable<Void> {
        return Observable
            .just(())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func moveDrafts(draftIds: [String], to folderId: String) -> Observable<Void> {
        return Observable
            .just(())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func getFolderList(offset: Int, limit: Int, sortMode: SortModel?) -> Observable<PagingInfo<CloudFolder>> {
        
        let total = 11
        func genDocData(number: Int) -> String {
            """
                    {
                      "status": "00",
                      "devices": [
                        {
                          "folder_id": "3K0XXXXX-83XX-HEXX-KIXX-29KH83XXXXXX",
                          "folder_name": "ドラえもん"
                        },
                        {
                          "folder_id": "3K0XXXXX-83XX-HEXX-KIXX-29KH83XXXXX1",
                          "folder_name": "ドラえもん1"
                        },
                      ]
                    }
            """
        }
        
        let maxOffset = max(offset, min(offset + limit, total))
        let documents: [String] = (offset..<maxOffset).map({ genDocData(number: $0) })
        
        
        let rawData =
        """
        {
          "status": "\(GooAPIStatus.maintenanceCannotUpdate.rawValue)",
          "total": \(total),
          "offset": \(offset),
          "limit": \(limit),
          "documents": [ \(documents.joined(separator: ",")) ]
        }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .map({ (data) -> GooResponseFolders in
                let result = try autoreleasepool(invoking: { () -> GooResponseFolders in
                    return try JSONDecoder().decode(GooResponseFolders.self, from: data)
                })
                return result
            })
            .flatMap({ (response) -> Observable<PagingInfo<CloudFolder>> in
                let pagingInfo = PagingInfo(offset: response.offset,
                                            limit: response.limit,
                                            totalItems: response.total,
                                            hasMorePages: response.data.count == response.limit,
                                            items: response.data,
                                            name: "")
                
                if response.status == .normal {
                    return Observable.just(pagingInfo)
                }
                
                return Observable.error(response.status.getError(data: pagingInfo)!)
            })
    }
    
    public func addOrUpdateFolder(_ folderId: String, name: String) -> Observable<Void> {
        let rawData = " {\"status\": \"\(GooAPIStatus.duplicateFolder.rawValue)\" } "
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ data -> GooResponseStatusCode in
                let result = try autoreleasepool(invoking: { () -> GooResponseStatusCode in
                    return try JSONDecoder().decode(GooResponseStatusCode.self, from: data)
                })
                return result
            })
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError()!)
            })
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func deleteFolder(_ id: String) -> Observable<Void> {
        return Observable
            .just(())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func getAccountInfo() -> Observable<String> {
//        let rawData = "{ \"status\": \"\(GooAPIStatus.maintenanceCannotUpdate.rawValue)\", \"account_name\": \"test\" }"
        let rawData = "{ \"status\": \"\(GooAPIStatus.maintenance.rawValue)\" }"
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ data -> GooResponseAccountInfo in
                let result = try autoreleasepool(invoking: { () -> GooResponseAccountInfo in
                    return try JSONDecoder().decode(GooResponseAccountInfo.self, from: data)
                })
                return result
            })
            .flatMap({ response -> Observable<String> in
                if response.status == .normal {
                    return Observable.just(response.data)
                }
                
                return Observable.error(response.status.getError(data: response.data)!)
            })
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func getAPIStatus() -> Observable<Void> {
        let rawData = " {\"status\": \"\(GooAPIStatus.normal.rawValue)\" } "
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ data -> GooResponseStatusCode in
                let result = try autoreleasepool(invoking: { () -> GooResponseStatusCode in
                    return try JSONDecoder().decode(GooResponseStatusCode.self, from: data)
                })
                return result
            })
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError()!)
            })
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func getCookieInfo() -> Observable<GooResponse<CookieInfo>> {
        let rawData =
        """
          {
            "status": "00",
            "data": {
              "GOO_ID": "",
              "USER_ID": "",
              "GOOID_TICKET_MANAGER_OUTPUT_EXPIRED": "true"
            }
          }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ (data) in
                let result = try autoreleasepool(invoking: { () -> GooResponse<CookieInfo> in
                    return try JSONDecoder().decode(GooResponse<CookieInfo>.self, from: data)
                })
                return result
            })
    }
    
    public func sendReceiptInfo(productId: String) -> Observable<Void> {
        return Observable
            .just(())
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
    
    public func getBillingStatus() -> Observable<GooResponseBillingInfo> {
        let rawData =
        """
          {
            "status": "00",
            "billing_status": 1,
            "platform": "appStore",
          }
        """
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ (data) in
                let result = try autoreleasepool(invoking: { () -> GooResponseBillingInfo in
                    return try JSONDecoder().decode(GooResponseBillingInfo.self, from: data)
                })
                return result
            })
    }
    
    public func backupDraftRestore(document: Document, backupDocument: CloudBackupDocument) -> Observable<Void> {
        let rawData = " {\"status\": \"\(GooAPIStatus.duplicateFolder.rawValue)\" } "
        
        return Observable.just(rawData)
            .map({ $0.data(using: .utf8) })
            .unwrap()
            .map({ data -> GooResponseStatusCode in
                let result = try autoreleasepool(invoking: { () -> GooResponseStatusCode in
                    return try JSONDecoder().decode(GooResponseStatusCode.self, from: data)
                })
                return result
            })
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError()!)
            })
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
    }
}
