//
//  NamingUseCase.swift
//  GooDic
//
//  Created by ttvu on 12/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol NamingUseCaseProtocol: AuthenticationUseCaseProtocol {
    // local
    func exists(folderName: String) -> Observable<Folder?>
    func createFolder(name: String, manualIndex: Double?) -> Observable<Void>
    func updateFolder(folder: Folder) -> Observable<Void>
    
    // cloud
    func createCloudFolder(name: String) -> Observable<Void>
    func updateCloudFolder(folder: Folder) -> Observable<Void>
}

struct NamingUseCase: NamingUseCaseProtocol {
    
    struct Constant {
        static let maxContent: Int = 500
    }
    
    @GooInject var dbService: DatabaseService
    @GooInject var cloudService: CloudService
    
    func exists(folderName: String) -> Observable<Folder?> {
        return dbService.gateway
            .getFolder(with: folderName)
            .map ({ list -> Folder? in
                list.first?.folder
            })
    }
    
    func createFolder(name: String, manualIndex: Double?) -> Observable<Void> {
        do {
            let data = try SortModel.valueDefaultDraft.toData()
            return dbService.gateway.update(folder: Folder(name: name, sortModelData: data, manualIndex: manualIndex, hasSortManual: false))
        } catch {
            print(error.localizedDescription)
        }
        return Observable.empty()
    }
    
    func updateFolder(folder: Folder) -> Observable<Void> {
        return dbService.gateway.update(folder: folder)
    }
    
    func createCloudFolder(name: String) -> Observable<Void> {
        let newId = UUID().uuidString
        return cloudService.gateway
            .addOrUpdateFolder(newId, name: name)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func updateCloudFolder(folder: Folder) -> Observable<Void> {
        guard let id = folder.id.cloudID else {
            return Observable.empty()
        }
        
        return cloudService.gateway
            .addOrUpdateFolder(id, name: folder.name)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
}
