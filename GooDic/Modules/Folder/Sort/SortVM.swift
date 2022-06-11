//
//  SortVM.swift
//  GooDic
//
//  Created by haiphan on 09/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct SortVM {
    var navigator: SortNavigateProtocol
    var useCase: SortUseCaseProtocol
    var openfromScreen: SortVM.openfromScreen
    var sortModel: SortModel
    var folder: Folder?
}

extension SortVM: ViewModelProtocol {
    
    public enum openfromScreen {
        case folderLocal, folderCloud, draftsLocal, draftsCloud
        
        var textParam: String {
            switch self {
            case .folderCloud: return "folderSortOrder"
            case .draftsCloud: return "documentSortOrder"
            case .draftsLocal, .folderLocal: return ""
            }
        }
    }
    
    struct Input {
        let dismissEvent: Driver<Void>
        let updateSortEvent: Driver<SortModel>
        let moveToPreniumEvent: Driver<Void>
        let updateRotationEvent: Driver<CGSize>
    }
    
    struct Output {
        let dismissEvent: Driver<Void>
        let updateSortEvent: Driver<SortModel>
        let getSortModel: Driver<SortModel>
        let postSort: Driver<Void>
        let error: Driver<Void>
        let openfromScreen: Driver<SortVM.openfromScreen>
        let getBillingInfo: Driver<BillingInfo>
        let moveToPreniumEvent: Driver<Void>
        let updateRotationEvent: Driver<CGSize>
    }
    
    func transform(_ input: Input) -> Output {
        
        let sortModeEvent: PublishSubject<SortModel> = PublishSubject.init()
        let errorTracker = ErrorTracker()
        let retryLoadData: BehaviorRelay<Int> = BehaviorRelay.init(value: 0)
        var sortModel: SortModel = AppSettings.sortModel
        
        let dismiss = input.dismissEvent
            .do { _ in
                self.navigator.dismiss()
            }
        
        let updateSortEvent = input.updateSortEvent.do { sort in
            switch self.openfromScreen {
            case .folderCloud, .draftsCloud:
                sortModel = sort
                retryLoadData.accept(0)
                sortModeEvent.onNext(sort)
            case .folderLocal, .draftsLocal:
                self.navigator.updateSort(sort: sort)
            }
        }
        
        let getSortModel = Driver.just(self.sortModel)
        
        let postSort = Observable.merge(sortModeEvent, retryLoadData.filter{ $0 > 0 }.flatMap { _ in Driver.just(sortModel) } )
            .flatMap({ sort -> Driver<Void> in
                switch self.openfromScreen {
                case .draftsCloud:
                    return self.useCase.postDraftSetiings(sortMode: sort,
                                                          settingKey: self.openfromScreen.textParam,
                                                          folderId: AppManager.shared.getFolderId(folder: self.folder))
                        .trackError(errorTracker).asDriverOnErrorJustComplete()
                case .folderCloud:
                    return self.useCase.postWebSetiings(sortMode: sort, settingKey: self.openfromScreen.textParam).trackError(errorTracker).asDriverOnErrorJustComplete()
                case .folderLocal, .draftsLocal: return Driver.just(())
                }
                
            })
            .flatMap { Driver.just(sortModel) }
            .do(onNext: { sort in
                self.navigator.updateSort(sort: sort)
            }).asDriverOnErrorJustComplete()
            .mapToVoid()
                
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
                                .showMessage(L10n.FolderBrowser.Error.unregisteredDevice)
                                .asDriverOnErrorJustComplete()
                            
                        case .maintenance:
                            return self.navigator
                                .showMessage(L10n.FolderBrowser.Error.maintenance)
                                .asDriverOnErrorJustComplete()
                            
                        case .maintenanceCannotUpdate:
                            return self.navigator
                                .showMessage(L10n.FolderBrowser.Error.maintenanceCannotUpdate)
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
                
        let openfromScreen = Driver.just(self.openfromScreen)
        
        let getBillingInfo = self.useCase.getBillingInfo()
            .asDriverOnErrorJustComplete()
            .do { billing in
                if billing.billingStatus == .paid {
                    self.navigator.updateHeightViewAfterPaid()
                }
            }
        
        let moveToPreniumEvent = input.moveToPreniumEvent
            .do(onNext: self.navigator.moveToPrenium)
        
        let updateRotationEvent = input.updateRotationEvent
            .do { size in
                self.navigator.updateSizeWithRotation(size: size)
            }


        return Output(
            dismissEvent: dismiss,
            updateSortEvent: updateSortEvent,
            getSortModel: getSortModel,
            postSort: postSort,
            error: error,
            openfromScreen: openfromScreen,
            getBillingInfo: getBillingInfo,
            moveToPreniumEvent: moveToPreniumEvent,
            updateRotationEvent: updateRotationEvent
        )}
}
