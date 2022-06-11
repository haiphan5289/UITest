//
//  HomeUseCase.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol HomeUseCaseProtocol: AuthenticationUseCaseProtocol {
    func checkAPIStatus() -> Observable<Void>
    
    func showAddNewDocumentTooltip() -> Bool
    func learnedAddNewDocumentTooltip() -> Observable<Void>
    func showEditModeTooltip() -> Bool
    func learnedEditModeTooltip() -> Observable<Void>
    func showSwipeActionInDocument() -> Bool
    func isNewUser() -> Bool
    func getNotiHomeBanner() -> Observable<NotificationBannerHome?>
    func scheduleForceCloseBanner() -> Double
    func userForceCloseBanner()
    func autoCloseBannerIfNeed() -> Observable<Void>
}

struct HomeUseCase: HomeUseCaseProtocol {
    @GooInject var cloudService: CloudService
    @GooInject var remoteConfigService: RemoteConfigService
    
    func checkAPIStatus() -> Observable<Void> {
        cloudService.gateway
            .getAPIStatus()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    func showAddNewDocumentTooltip() -> Bool {
        return AppSettings.guideUserToAddNewDocument == false
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
    
    func getNotiHomeBanner() -> Observable<NotificationBannerHome?> {
        return remoteConfigService.gateway.titleForBanner()
    }
    
    func scheduleForceCloseBanner() -> Double {
        return AppSettings.expirationDateHomeBanner.timeIntervalSince(Date())
    }
    
    func userForceCloseBanner() {
        AppSettings.isUserHasBeenCloseHomeBanner = true
    }
    
    func autoCloseBannerIfNeed() -> Observable<Void> {
        if scheduleForceCloseBanner() <= 0 {
            return Observable.empty()
        }
        return Observable<Int>
            .interval(.seconds(Int(scheduleForceCloseBanner())), scheduler: MainScheduler.instance)
            .mapToVoid().debug("auto-close-banner")
    }
}
