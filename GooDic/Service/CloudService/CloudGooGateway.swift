//
//  CloudGooGateway.swift
//  GooDic
//
//  Created by ttvu on 11/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import GooidSDK

public struct CloudGooGateway: CloudGatewayProtocol {
    
    public func addBackUp(draft: Document) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let apiBackupCheck = String(format: Environment.apiAddBackUp , draft.id)
        let urlString = "\(Environment.apiScheme + Environment.apiHost + apiBackupCheck)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : Any] = [
            "device_id": deviceId,
            "document_id": draft.id,
            "document_title": draft.title,
            "document_text": draft.content,
            "cursor_position": "\(draft.cursorPosition)",
            
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func backupCheck(drafts: [Document]) -> Observable<Bool> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiBackupCheck)"
        let header: [String: String] = ["Cookie": cookie]
        let documentIdList = drafts.map { $0.id }.compactMap { $0 }.filter { $0 != "" }
            .map { id -> [String: String] in
                return ["document_id": id]
            }
        
        let params: [String : Any] = [
            "device_id": deviceId,
            "document_id_list": documentIdList,
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseBackUpCheck.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Bool> in
                if response.status == .normal {
                    return Observable.just(response.backupExist ?? false)
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func sortDrafts(drafts: [Document], sortedAt: String, folderId: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiDraftSortManual)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : Any] = [
            "device_id": deviceId,
            "folder_id": folderId,
            "document_id_list": drafts.map { $0.id }.compactMap { $0 }.filter { $0 != "" },
            "sorted_at": sortedAt
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseFoldersSort.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func postDraftSetiings(sortMode: SortModel, settingKey: String, folderId: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiSortDraftSetting)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "folder_id": folderId,
            "setting_key": settingKey,
            "setting_value": "\(sortMode.sortName.rawValue),\(sortMode.getAsc())"
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(data: response, errorMessage: response.errorCode)!)
            })
    }
    
    public func getDraftSettings(settingKey: String, folderId: String) -> Observable<String> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiSortDraftSetting)"
                
                let header: [String: String] = ["Cookie": cookie]
                
                let params: [String : String] = [
                    "device_id": deviceId,
                    "folder_id": folderId,
                    "setting_key": settingKey
                ]
                
                return GooAPIRouter
                    .request(ofType: GooResponseSortValue.self,
                             url: urlString,
                             urlParams: params,
                             method: .get,
                             header: header)
                    .flatMap({ response -> Observable<String> in
                        if response.status == .normal {
                            return Observable.just(response.value)
                        }
                        
                        return Observable.error(response.status.getError(errorMessage: response.errorCode)! )
                    })

    }
    
    public func postWebSetiings(sortMode: SortModel, settingKey: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiWebSettings)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "setting_key": settingKey,
            "setting_value": "\(sortMode.sortName.rawValue),\(sortMode.getAsc())"
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(data: response, errorMessage: response.errorCode)!)
            })
    }
    
    public func getWebSettings(settingKey: String) -> Observable<String> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiWebSettings)"
                
                let header: [String: String] = ["Cookie": cookie]
                
                let params: [String : String] = [
                    "device_id": deviceId,
                    "setting_key": settingKey
                ]
                
                return GooAPIRouter
                    .request(ofType: GooResponseSortValue.self,
                             url: urlString,
                             urlParams: params,
                             method: .get,
                             header: header)
                    .flatMap({ response -> Observable<String> in
                        if response.status == .normal {
                            return Observable.just(response.value)
                        }
                        
                        return Observable.error(response.status.getError(errorMessage: response.errorCode)! )
                    })

    }
    
    public func postBackupSettings(settingBackupModel: SettingBackupModel, settingKey: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiWebSettings)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "setting_key": settingKey,
            "setting_value": settingBackupModel.toStringJSON()
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(data: response, errorMessage: response.errorCode)!)
            })
    }
    
    public func getBackupSettings(settingKey: String) -> Observable<SettingBackupModel?> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiWebSettings)"
                
                let header: [String: String] = ["Cookie": cookie]
                
                let params: [String : String] = [
                    "device_id": deviceId,
                    "setting_key": settingKey
                ]
                
                return GooAPIRouter
                    .request(ofType: GooResponseSettingBackup.self,
                             url: urlString,
                             urlParams: params,
                             method: .get,
                             header: header)
                    .flatMap({ response -> Observable<SettingBackupModel?> in
                        if response.status == .normal {
                            return Observable.just(response.value)
                        }
                        
                        return Observable.error(response.status.getError(errorMessage: response.errorCode)! )
                    })

    }
    
    public func getRegisteredDevices() -> Observable<[DeviceInfo]> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiListDevice)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        return GooAPIRouter
            .request(ofType: GooResponseDevices.self,
                     url: urlString,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<[DeviceInfo]> in
                if response.status == .normal {
                    return Observable.just(response.data)
                }
                
                return Observable.error(response.status.getError(data: response.data, errorMessage: response.errorCode)! )
            })
    }
    
    public func deleteDevice(deviceId: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiDeleteDevice)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)! )
            })
    }
    
    public func addDevice(name: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiAddDevice)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "device_name": name
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)! )
            })
    }
    
    public func getDeviceName(deviceCode: String) -> Observable<String> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiIOSDeviceName + deviceCode)"
        let header: [String: String] = ["Cookie": cookie]
        
        return GooAPIRouter
            .request(ofType: DeviceName.self,
                     url: urlString,
                     method: .get,
                     header: header)
            .flatMap({ (response) -> Observable<String> in
                if response.status == .normal {
                    return Observable.just(response.deviceName)
                }
                
                return Observable.error(response.status.getError(data: response.deviceName, errorMessage: response.errorCode)!)
            })
    }
    
    public func getDraftList(query: CloudDraftQuery, offset: Int, limit: Int, sort: SortModel) -> Observable<PagingInfo<CloudDocument>> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiGetDrafts)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        var params: [String : String]
        switch query {
        case .all:
            params = [
                "device_id": deviceId,
                "filtering": "false",
                "folder_id": "",
                "offset": "\(offset)",
                "limit": "\(limit)"
            ]
        case .uncategoried:
            params = [
                "device_id": deviceId,
                "filtering": "true",
                "folder_id": "",
                "offset": "\(offset)",
                "limit": "\(limit)"
            ]
        case let .folderId(folderId):
            params = [
                "device_id": deviceId,
                "filtering": "true",
                "folder_id": folderId,
                "offset": "\(offset)",
                "limit": "\(limit)"
            ]
        }
        params["order"] = "\(sort.sortName.rawValue)"
        params["asc"] = "\(sort.asc)"
        
        return GooAPIRouter
            .request(ofType: GooResponseDocuments.self,
                     url: urlString,
                     urlParams: params,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<PagingInfo<CloudDocument>> in
                let pagingInfo = PagingInfo(offset: response.offset,
                                            limit: response.limit,
                                            totalItems: response.total,
                                            hasMorePages: response.data.count == response.limit,
                                            items: response.data,
                                            name: response.folderName,
                                            sortedAt: response.sortedAt)
                
                if response.status == .normal {
                    return Observable.just(pagingInfo)
                }
                
                return Observable.error(response.status.getError(data: pagingInfo, errorMessage: response.errorCode)!)
            })
    }
    
    public func getDraftDetail(_ draft: CloudDocument) -> Observable<CloudDocument> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiGetDraftDetail + "\(draft.id)")"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseDocumentDetail.self,
                     url: urlString,
                     urlParams: params,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<CloudDocument> in
                let item = CloudDocument(id: draft.id,
                                         title: response.title,
                                         content: response.text,
                                         updatedAt: response.update,
                                         folderId: draft.folderId,
                                         folderName: draft.folderName,
                                         cursorPosition: response.cursorPosition,
                                         manualIndex: nil)
                
                if response.status == .normal {
                    return Observable.just(item)
                }
                
                return Observable.error(response.status.getError(data: item, errorMessage: response.errorCode)!)
            })
    }
    
    public func addDraft(_ draft: CloudDocument) -> Observable<Date> {
        addOrUpdateDraft(draft, overwrite: false, reuseLastUpdate: true)
    }
    
    public func updateDraft(_ draft: CloudDocument, overwrite: Bool, reuseLastUpdate: Bool) -> Observable<Date> {
        addOrUpdateDraft(draft, overwrite: overwrite, reuseLastUpdate: reuseLastUpdate)
    }
    
    private func addOrUpdateDraft(_ draft: CloudDocument, overwrite: Bool, reuseLastUpdate: Bool) -> Observable<Date> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiAddDraft)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        var params: [String : String] = [
            "device_id": deviceId,
            "document_id": draft.id,
            "folder_id": draft.folderId,
            "document_title": draft.title.isEmpty ? "" : draft.title,
            "document_text": draft.content,
            "cursor_position": "\(draft.cursorPosition)",
            "document_last_update": FormatHelper.dateFormatterOnGatewayCloud.string(from: draft.updatedAt),
            "document_overwrite": overwrite ? "true" : "false"
        ]
        
        if reuseLastUpdate {
            params["overwrite_last_update"] = FormatHelper.dateFormatterOnGatewayCloud.string(from: draft.updatedAt)
        }
        
        return GooAPIRouter
            .request(ofType: GooResponseUpdateDocument.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Date> in
                if response.status == .normal {
                    return Observable.just(response.lastUpdate)
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func deleteDrafts(draftIds: [String]) -> Observable<Void> {
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiDeleteDraft)"
        
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let header: [String: String] = ["Cookie": cookie]
        let list = draftIds.map({ ["document_id":$0] })
        
        let params: [String : Encodable] = [
            "device_id": deviceId,
            "document_id_list": list
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
        
    public func moveDrafts(draftIds: [String], to folderId: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiMoveDrafts)"
        
        let header: [String: String] = ["Cookie": cookie]
        let list = draftIds.map({ ["document_id":$0] })
        
        let params: [String : Encodable] = [
            "device_id": deviceId,
            "document_id_list": list,
            "folder_id": folderId
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func getFolderList(offset: Int, limit: Int, sortMode: SortModel? = nil) -> Observable<PagingInfo<CloudFolder>> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiGetFolders)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        var params: [String : String] = [
            "device_id": deviceId,
            "offset": "\(offset)",
            "limit": "\(limit)",
        ]
        if let sort = sortMode {
            params["order"] = "\(sort.sortName.rawValue)"
            params["asc"] = "\(sort.asc)"
        }
        
        return GooAPIRouter
            .request(ofType: GooResponseFolders.self,
                     url: urlString,
                     urlParams: params,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<PagingInfo<CloudFolder>> in
                let pagingInfo = PagingInfo(offset: response.offset,
                                            limit: response.limit,
                                            totalItems: response.total,
                                            hasMorePages: response.data.count == response.limit,
                                            items: response.data,
                                            name: "",
                                            sortedAt: response.sortedAt)
                
                if response.status == .normal {
                    return Observable.just(pagingInfo)
                }
                
                return Observable.error(response.status.getError(data: pagingInfo, errorMessage: response.errorCode)!)
            })
    }
    
    public func addOrUpdateFolder(_ folderId: String, name: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiAddFolder)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "folder_id": folderId,
            "folder_name": name
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func deleteFolder(_ id: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiDeleteFolder)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "folder_id": id
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func sortFolders(folders: [Folder], sortedAt: String) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiFoldersSort)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : Any] = [
            "device_id": deviceId,
            "folder_id_list": folders.map { $0.id.cloudID }.compactMap { $0 }.filter { $0 != "" },
            "sorted_at": sortedAt
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        return GooAPIRouter
            .request(ofType: GooResponseFoldersSort.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(errorMessage: response.errorCode)!)
            })
    }
    
    public func getAccountInfo() -> Observable<String> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiAccountInfo)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        return GooAPIRouter
            .request(ofType: GooResponseAccountInfo.self,
                     url: urlString,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<String> in
                if response.status == .normal {
                    return Observable.just(response.data)
                }
                
                if response.status == .maintenance {
                    return Observable.error(GooServiceError.maintenance(response.data))
                }
                
                return Observable.error(response.status.getError(data: response.data, errorMessage: response.errorCode)!)
            })
    }
    
    public func getAPIStatus() -> Observable<Void> {
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiValidationServer)"
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     method: .get)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(data: nil, errorMessage: response.errorCode)!)
            })
    }
    
    public func getCookieInfo() -> Observable<GooResponse<CookieInfo>> {
        return Observable.empty()
    }
    
    public func sendReceiptInfo(productId: String) -> Observable<Void> {
        guard
            let bundleId = Bundle.main.bundleIdentifier,
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: receiptUrl)
            else {
            return Observable.error(GooServiceError.receiptEmpty)
          }
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let urlString = "\(Environment.apiScheme + Environment.apiRRHost + Environment.apiVerifyReceipt)"
        let header: [String: String] = ["Cookie": cookie]
        
        let receiptString = receiptData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        print(receiptString)
        let params: [String : String] = [
            "receipt-data": receiptString,
            "bundle_id": bundleId,
            "product_id": productId
        ]
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        
        
        return GooAPIRouter
            .request(ofType: GooResponseVerifyReceipt.self,
                     url: urlString,
                     httpBody: data,
                     method: .post,
                     header: header,
                     needCheckHttpStatusCode: true)
            .flatMap({ response -> Observable<Void> in
                if response.valid == true {
                    GATracking.sendAFEventPurchase(values: params)
                    return Observable.just(())
                }
                
                return Observable.error(GooServiceError.otherError(response.errors.first ?? L10n.Server.Error.Title.otherError))
            })
    }
    
    public func getBillingStatus() -> Observable<GooResponseBillingInfo> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiBillingStatus)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        return GooAPIRouter
            .request(ofType: GooResponseBillingInfo.self,
                     url: urlString,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<GooResponseBillingInfo> in
                if response.status == .normal {
                    return Observable.just(response)
                }
                
                return Observable.error(response.status.getError(data: response, errorMessage: response.errorCode)!)
            })
    }
    
    public func getBackupDraftList(document: Document) -> Observable<[CloudBackupDocument]> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + String(format: Environment.apiGetBackupDrafts, document.id))"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "document_id": document.id,
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseBackupDraftList.self,
                     url: urlString,
                     urlParams: params,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<[CloudBackupDocument]> in
                if response.status == .normal {
                    return Observable.just(response.data)
                }
                
                return Observable.error(response.status.getError(data: response.data, errorMessage: response.errorCode)! )
            })
    }
    
    public func getBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument) -> Observable<CloudBackupDocument> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + String(format: Environment.apiGetBackupDrafts, document.id, backupDocument.id))"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "document_id": document.id,
            "backup_id": backupDocument.id
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseBackupDraftDetail.self,
                     url: urlString,
                     urlParams: params,
                     method: .get,
                     header: header)
            .flatMap({ response -> Observable<CloudBackupDocument> in
                let item = CloudBackupDocument(id: "", title: response.title, content: response.content, updatedAt: response.updatedAt, device: response.device, cursorPosition: response.cursorPosition)

                
                if response.status == .normal {
                    return Observable.just(item)
                }
                
                return Observable.error(response.status.getError(data: item, errorMessage: response.errorCode)!)
            })
    }
    
    public func backupDraftRestore(document: Document, backupDocument: CloudBackupDocument) -> Observable<Void> {
        let cookie = GooidSDK.sharedInstance.generateCookies() ?? ""
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let urlString = "\(Environment.apiScheme + Environment.apiHost + Environment.apiWebSettings)"
        
        let header: [String: String] = ["Cookie": cookie]
        
        let params: [String : String] = [
            "device_id": deviceId,
            "document_id": document.id,
            "backup_id": backupDocument.id,
            "folder_id": document.folderId.cloudID ?? "",
 
        ]
        
        return GooAPIRouter
            .request(ofType: GooResponseStatusCode.self,
                     url: urlString,
                     httpBody: params,
                     method: .post,
                     header: header)
            .flatMap({ response -> Observable<Void> in
                if response.status == .normal {
                    return Observable.just(())
                }
                
                return Observable.error(response.status.getError(data: response, errorMessage: response.errorCode)!)
            })
    }
}
