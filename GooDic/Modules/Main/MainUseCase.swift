//
//  MainUseCase.swift
//  GooDic
//
//  Created by ttvu on 10/12/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol MainUseCaseProtocol {
    func getAllDocuments() -> Observable<[Document]>
    func showTrashTooltip() -> Bool
    func learnedTrashTooltip() -> Observable<Void>
    func learnedSwipeDraftTooltip()
    func learnedSwipeFolderTooltip()
    func isNewUser() -> Bool
}

struct MainUseCase {
    @GooInject var dbService: DatabaseService
    
    func getAllDocuments() -> Observable<[Document]> {
        return dbService.gateway.getAllDocuments().map ({ data -> [Document] in
            return data.map({ $0.document })
        })
    }
    
    func showTrashTooltip() -> Bool {
        return AppSettings.guideUserToTrash == false
    }
    
    func learnedTrashTooltip() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            AppSettings.guideUserToTrash = true
            
            observer.onNext(())
            
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func learnedSwipeDraftTooltip() {
        AppSettings.guideUserToSwipeDraft = true
    }
    
    func learnedSwipeFolderTooltip() {
        AppSettings.guideUserToSwipeFolder = true
    }
    
    func isNewUser() -> Bool {
        let currentBuildVersion = Int(Bundle.main.applicationBuild) ?? 0
    
        if AppSettings.firstInstallBuildVersion == -1 {
            return false
        }
        
        return AppSettings.firstInstallBuildVersion == currentBuildVersion
    }
}
