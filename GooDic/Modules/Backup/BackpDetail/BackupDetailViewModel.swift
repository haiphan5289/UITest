//
//  BackupDetailViewModel.swift
//  GooDic
//
//  Created by Vinh Nguyen on 26/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


struct BackupDetailViewModel {
    var navigator: BackupDetailNavigateProtocol
    var useCase: BackupDetailUseCaseProtocol
    let document: Document
    let backupDocument: CloudBackupDocument
    
    
    init(useCase: BackupDetailUseCaseProtocol,
         navigator: BackupDetailNavigateProtocol,
         document: Document,
         backupDocument: CloudBackupDocument) {
        self.useCase = useCase
        self.navigator = navigator
        self.document = document
        self.backupDocument = backupDocument
    }
}

extension BackupDetailViewModel: ViewModelProtocol {
    struct Input {
        let loadDataTrigger: Driver<Void>
        let restoreBackupDraftTrigger: Driver<Void>
    }
    
    struct Output {

        let loadData: Driver<(Document,CloudBackupDocument)>
        let showAlertRestoreBackupDraft: Driver<Void>
        let restoreBackupDraft: Driver<Void>
        let error: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
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
                        
                    case .folderNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.folderNotFound)
                            .asDriverOnErrorJustComplete()
                        
                    case .backupNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.backupNotFound)
                            .asDriverOnErrorJustComplete()
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate(_):
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
        
        let data = input.loadDataTrigger
            .flatMap{ _ -> Driver<(Document, CloudBackupDocument)> in
                let object = (self.document,self.backupDocument)
                return Driver.just(object)
            }
        
        let postRestoreBackupDraftTrigger: PublishSubject<Void> = PublishSubject.init()
        let showAlertRestoreBackupDraft = input.restoreBackupDraftTrigger.asObservable()
            .flatMap{
                return self.navigator
                    .showConfirmMessage(L10n.BackupDetail.RestoreConfirm.message,
                                        noSelection: L10n.Alert.cancel,
                                        yesSelection: L10n.Alert.ok)
                    .flatMap{ selection -> Observable<Void> in
                        if selection {
                            postRestoreBackupDraftTrigger.onNext(())
                        }
                        return Observable.just(())
                    }
            }
            .asDriverOnErrorJustComplete()
            
        
        let postRestoreBackupDraft = postRestoreBackupDraftTrigger.asObservable()
            .flatMap{
                self.useCase.backupDraftRestore(document: self.document, backupDocument: self.backupDocument)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .flatMap{
                        self.navigator.showMessage(L10n.BackupDetail.Restore.message)
                    }
            }
            .asDriverOnErrorJustComplete()
                
        return Output(
            loadData: data,
            showAlertRestoreBackupDraft: showAlertRestoreBackupDraft,
            restoreBackupDraft: postRestoreBackupDraft,
            error: errorHandler

        )
    }
}
