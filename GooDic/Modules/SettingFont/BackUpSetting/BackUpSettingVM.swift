//
//  DrawPresentVM.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct BackUpSettingVM {
    var navigator: BackUpSettingCoordinatorProtocol
    var useCase: BackUpSettingUseCaseProtocol
    var drafts: [Document]
}

extension BackUpSettingVM: ViewModelProtocol {
    struct Input {
        let actionEvent: Driver<BackUpSettingVC.Action>
    }
    
    struct Output {
        let actionEvent: Driver<BackUpSettingVC.Action>
        let getUserInfo: Driver<BillingInfo>
        let getSettingFont: Driver<SettingFont>
        let doApiBackUpCheck: Driver<Void>
        let errorTracker: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let apiBackUpCheck: PublishSubject<Void> = PublishSubject.init()
        let actionEvent = input.actionEvent
            .do { action in
                switch action {
                case .dismiss: self.navigator.dismissDelegate()
                case .share: self.navigator.actionShare()
                case .moveToFont: self.navigator.moveToFont()
                case .moveToBackUp:
                    if AppManager.shared.billingInfo.value.billingStatus == .paid {
                        apiBackUpCheck.onNext(())
                    } else {
                        self.navigator.moveToPrenium()
                    }
                }
            }
        
        let errorTracker = ErrorTracker()
        let retrySession: BehaviorRelay<Int> = BehaviorRelay.init(value: 0)
        let doApiBackUpCheck =  Observable.merge(apiBackUpCheck, retrySession.filter { $0 > 0 }.mapToVoid() )
            .flatMap { _ -> Driver<Bool> in
                return self.useCase.backUpCheck(drafts: self.drafts).trackError(errorTracker).asDriverOnErrorJustComplete()
            }
            .do(onNext: { isBackUp in
                retrySession.accept(0)
                if isBackUp {
                    print("======== move to list BackUp \(isBackUp)")
                }
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let doErrorTracker = errorTracker
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
                                if retrySession.value == 0 {
                                    retrySession.accept(1)
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
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.BackUpSetting.notFound)
                            .asDriverOnErrorJustComplete()
                    default:
                        return Driver.empty()
                    }
                }
                
                return Driver.just(())
            })
            .asDriverOnErrorJustComplete()

        
        let getUserInfo = self.useCase.getUserInfo().asDriverOnErrorJustComplete()
        let getSettingFont = Observable.merge(self.useCase.getSettingFont(), self.navigator.updateSetting)
            .asDriverOnErrorJustComplete()
        
        return Output(actionEvent: actionEvent,
                      getUserInfo: getUserInfo,
                      getSettingFont: getSettingFont,
                      doApiBackUpCheck: doApiBackUpCheck,
                      errorTracker: doErrorTracker
        )
    }
}
