//
//  DraftsUseCase.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import CoreData

protocol DraftsUseCaseProtocol: CheckAPIFeature {
    func showAddNewDocumentTooltip() -> Bool
    func learnedAddNewDocumentTooltip() -> Observable<Void>
    func showEditModeTooltip() -> Bool
    func learnedEditModeTooltip() -> Observable<Void>
    func showSwipeActionInDocument() -> Bool
    func isNewUser() -> Bool
    func getFolder(folderName: String) -> Folder?
}

struct DraftsUseCase: DraftsUseCaseProtocol {
    @GooInject var cloudService: CloudService
    @GooInject var dbService: DatabaseService
    
    func showAddNewDocumentTooltip() -> Bool {
        return AppSettings.guideUserToAddNewDocument == false
    }
    
    func getFolder(folderName: String) -> Folder? {
        return dbService.gateway.getFolder(with: folderName).map { $0.folder }.first
    }
    
    func learnedAddNewDocumentTooltip() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            AppSettings.guideUserToAddNewDocument = true
            
            observer.onNext(())
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func showEditModeTooltip() -> Bool {
        return AppSettings.guideUserToEditMode == false
    }
    
    func learnedEditModeTooltip() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            AppSettings.guideUserToEditMode = true
            
            observer.onNext(())
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func showSwipeActionInDocument() -> Bool {
        return AppSettings.guideUserToSwipeDraft == false
    }
    
    func isNewUser() -> Bool {
        let currentBuildVersion = Int(Bundle.main.applicationBuild) ?? 0
    
        if AppSettings.firstInstallBuildVersion == -1 {
            return false
        }
        
        return AppSettings.firstInstallBuildVersion == currentBuildVersion
    }
}
