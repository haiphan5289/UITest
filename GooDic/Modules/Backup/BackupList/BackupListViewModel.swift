//
//  BackupListViewModel.swift
//  GooDic
//
//  Created by Vinh Nguyen on 25/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

struct BackupListViewModel {
    var navigator: BackupListNavigateProtocol
    var useCase: BackupListUseCaseProtocol
    let document: Document
    
    init(useCase: BackupListUseCaseProtocol, navigator: BackupListNavigateProtocol, document: Document) {
        self.useCase = useCase
        self.navigator = navigator
        self.document = document
    }
}

extension BackupListViewModel: ViewModelProtocol {
    struct Input {
        let loadDataTrigger: Driver<Void>
        let refreshTrigger: Driver<Void>
        let selectBackupDraftTrigger: Driver<IndexPath>
        let viewWillDisappear: Driver<Void>
    }
    
    struct Output {
        let loadData: Driver<[CloudBackupDocument]>
        let openedBackupDraft: Driver<Void>
        let error: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let loadDataTrigger = input.loadDataTrigger.map({ ScreenLoadingType.loading })
        let refreshTrigger = input.refreshTrigger.map({ ScreenLoadingType.reloading })
        let retryLoadData: BehaviorRelay<Int> = BehaviorRelay.init(value: 0)
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let error = errorTracker
                .asObservable()
                .flatMap({ (error) -> Driver<Void> in
                    if let error = error as? GooServiceError {
                        switch error {
                        case .terminalRegistration:
                            if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                                userInfo.deviceStatus = .unregistered
                                AppManager.shared.userInfo.accept(userInfo)
                            }
                            return self.navigator
                                .showMessage(L10n.Drafts.Error.unregisteredDevice)
                                .asDriverOnErrorJustComplete()
                        case .maintenance:
                            return self.navigator
                                .showMessage(L10n.Drafts.Error.maintenanceCannotUpdate)
                                .asDriverOnErrorJustComplete()
                        case .maintenanceCannotUpdate:
                            return self.navigator
                                .showMessage(L10n.Drafts.Error.maintenanceCannotUpdate)
                                .asDriverOnErrorJustComplete()
                        case .draftNotFound:
                            return self.navigator
                                .showMessage(L10n.Drafts.Error.draftNotFound)
                                .asDriverOnErrorJustComplete()
                        case .sessionTimeOut:
                            return self.useCase
                                .refreshSession()
                                .catchError({ (error) -> Observable<Void> in
                                    return self.navigator
                                        .showMessage(L10n.Sdk.Error.Refresh.session)
                                        .observeOn(MainScheduler.instance)
                                        .do(onNext: self.navigator.toForceLogout)
                                        .flatMap({ Observable.empty() })
                                            })
                                .do(onNext: {
                                    if retryLoadData.value == 0 {
                                        retryLoadData.accept(1)
                                    }
                                })
                                .asDriverOnErrorJustComplete()
                        case .authenticationError:
                            return self.useCase.logout()
                                .subscribeOn(MainScheduler.instance)
                                .do(onNext: self.navigator.toForceLogout)
                                .asDriverOnErrorJustComplete()
                        case .receiptInvalid:
                            return self.navigator
                                .showMessage(L10n.FolderBrowser.Error.receiptInvalid)
                                .asDriverOnErrorJustComplete()
                        case .otherError(let errorCode):
                            return self.navigator
                                .showMessage(errorCode: errorCode)
                                .asDriverOnErrorJustComplete()
                        default:
                            return Driver.empty()
                        }
                    }
                    
                    return Driver.just(())
                })
                .asDriverOnErrorJustComplete()
        
        let loadData = Driver.merge(
            loadDataTrigger,
            refreshTrigger,
            retryLoadData.asDriverOnErrorJustComplete().filter { $0 > 0 }
                .flatMap{ _ in Driver.just(ScreenLoadingType.loading)}
            )
            .flatMap{ _ -> Driver<[CloudBackupDocument]> in
                return self.useCase.fetchBackupDraftList(document: self.document)
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker).asDriverOnErrorJustComplete()
            }
            .do(onNext: { obj in
                retryLoadData.accept(0)
            })
                
        let selectedBackupDraft = input.selectBackupDraftTrigger
            .withLatestFrom(loadData) { ($0, $1) }
            .filter ({ (indexPath, items) -> Bool in
                indexPath.row < items.count
            })
            .map ({ (indexPath, items) -> CloudBackupDocument in
                return items[indexPath.row]
            })
                
        let openedBackupDraft = backupDraftDetailFlow(selectedBackupDocument: selectedBackupDraft,
                                                      cancelTrigger: input.viewWillDisappear)
        
        return Output(
            loadData: loadData,
            openedBackupDraft: openedBackupDraft,
            error: error
        )
    }
    
    private func backupDraftDetailFlow(selectedBackupDocument: Driver<CloudBackupDocument>,
                                 cancelTrigger: Driver<Void>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate(let data):
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.maintenanceCannotUpdate)
                            .asDriverOnErrorJustComplete()
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                            
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                        
                    case .receiptInvalid:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Error.receiptInvalid)
                            .asDriverOnErrorJustComplete()
                
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        let userAction = selectedBackupDocument.mapToVoid()
            .do(onNext: {
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let openedDraft = Driver.merge(userAction, retryAction)
            .withLatestFrom(Driver.combineLatest(selectedBackupDocument, activityIndicator.asDriver()))
            .flatMapLatest({ (obj) -> Driver<CloudBackupDocument> in
                return self.useCase.fetchBackupDraftDetail(document: self.document, backupDocument: obj.0)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .takeUntil(cancelTrigger.asObservable())
                    .asDriverOnErrorJustComplete()
            })
            .do(onNext: { backupDocument in
                self.navigator.toBackupDraftDetail(document: self.document, backupDocument: backupDocument)
            })
            .asDriver()
            .mapToVoid()
        
        return Driver.merge(openedDraft, errorHandler)
    }
}
