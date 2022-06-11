//
//  SettingBackupViewModel.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


struct SettingBackupViewModel {
    var navigator: SettingBackupNavigateProtocol
    var useCase: SettingBackupUseCaseProtocol
    
    let backupData: [SettingBackupData]
    let ruleBackupData: [SettingBackupData]
    let titleBackupData: [SettingBackupData]
    let minuteBackupData: [SettingBackupData]
    
    init(backupData: [SettingBackupData],
         ruleBackupData: [SettingBackupData],
         titleBackupData: [SettingBackupData],
         minuteBackupData: [SettingBackupData],
         useCase: SettingBackupUseCaseProtocol,
         navigator: SettingBackupNavigateProtocol) {
        self.backupData = backupData
        self.ruleBackupData = ruleBackupData
        self.titleBackupData = titleBackupData
        self.minuteBackupData = minuteBackupData
        self.useCase = useCase
        self.navigator = navigator
    }
}

extension SettingBackupViewModel: ViewModelProtocol {
    
    enum Constant {
        static let numberOfSection: Int = 4
    }
    
    struct Input {
        let loadDataTrigger: Driver<Void>
        let selectCellTrigger: Driver<IndexPath>
        let eventShowAlertEnableBackup: Driver<Void>
        let updateSettingBackupTrigger: Driver<SettingBackupModel>
    }
    
    struct Output {
        let data: Driver<SettingBackupModel?>
        let selectedCell: Driver<SettingBackupAction>
        let eventShowAlertEnableBackup: Driver<Void>
        let error: Driver<Void>
        let updateSettingBackup: Driver<SettingBackupModel>
    }
    
    func transform(_ input: Input) -> Output {
        var settingBackupModel: SettingBackupModel!
        let retryLoadData: BehaviorRelay<Int> = BehaviorRelay.init(value: 0)
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
                        case .draftNotFound:
                            return self.navigator
                                .showMessage(L10n.SettingBackup.Error.settingBackupNotFound)
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

        let data = input.loadDataTrigger
            .flatMap({ _ -> Driver<SettingBackupModel?> in
                self.useCase.getBackupSettings(settingKey: SettingBackupModel.SettingKey.backupSettings.textParam)
                    .trackError(errorTracker)
                    .asDriverOnErrorJustComplete()
            })
            .do(onNext: { obj in
                settingBackupModel = obj
                retryLoadData.accept(0)
            })
                
        let settingBackupData = [
            self.getSettingBackupData(),
            self.getSettingBackupTitleData(),
            self.getSettingBackupRuleData(),
            self.getSettingBackupMinuteData()
        ]
        let settingBackupDataTrigger = BehaviorSubject(value: settingBackupData)
        
        let updateMinuteTrugger: PublishSubject<SettingBackupModel> = PublishSubject.init()
        let selectedCell = input.selectCellTrigger
            .withLatestFrom(settingBackupDataTrigger.asDriverOnErrorJustComplete()) { ($0, $1) }
            .filter ({ (indexPath, items) -> Bool in
                indexPath.section == SettingBackUpSectionCell.settingBackupMinute.rawValue && AppManager.shared.billingInfo.value.billingStatus == .paid
            })
            .map ({ (indexPath, items) -> SettingBackupData in
                return items[indexPath.section][indexPath.row]
            })
            .do(onNext: { (obj) in
                switch obj.action {
                case .isSelectMinute:
                    let minute = Int(obj.title) ?? SettingBackupMinute.zero.integer
                    let setttingBackup = SettingBackupModel(
                        isBackup: settingBackupModel.isBackup ?? false,
                        isManualSaveBackup: settingBackupModel.isManualSaveBackup ?? false,
                        isPeriodicBackup: settingBackupModel.isPeriodicBackup ?? false,
                        interval: minute)
                    settingBackupModel = setttingBackup
                    updateMinuteTrugger.onNext(setttingBackup)
                    break
                case .none:
                    break
                case .isBackup:
                    break
                case .isManualSaveBackup:
                    break
                case .isPeriodicBackup:
                    break
                }})
            .map({ $0.action })
                
        let updateSettingBackupTrigger = Driver.merge(input.updateSettingBackupTrigger, updateMinuteTrugger.asDriverOnErrorJustComplete())
            .flatMap({ (obj) -> Driver<SettingBackupModel> in
                    settingBackupModel = obj
                    return Driver.just(obj)
            })

        let postSettingBackup = Observable.merge(updateSettingBackupTrigger.asObservable(), retryLoadData.filter{ $0 > 0 }.flatMap { _ in Driver.just(settingBackupModel) })
            .flatMap({ (model) -> Driver<Void> in
                return self.useCase.postBackupSettings(settingBackupModel: model, settingKey: SettingBackupModel.SettingKey.backupSettings.textParam)
                    .trackError(errorTracker)
                    .asDriverOnErrorJustComplete()
                }
            )
            .do(onNext: { _ in
                retryLoadData.accept(0)
            })
            .flatMap({ _ -> Driver<SettingBackupModel> in
                return Driver.just(settingBackupModel)
            })
        
        let eventShowAlertEnableBackup = input.eventShowAlertEnableBackup
            .asObservable()
            .flatMap({ _ -> Driver<Void> in
                return self.navigator.showMessage(L10n.SettingBackup.AlertEnableBackup.title).asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
        
        return Output(
            data: data,
            selectedCell: selectedCell,
            eventShowAlertEnableBackup: eventShowAlertEnableBackup,
            error: error,
            updateSettingBackup: postSettingBackup.asDriverOnErrorJustComplete()
        )
    }
    
    func numberOfSections() -> Int {
        return Constant.numberOfSection
    }
    
    func numberOfItems(at section: Int) -> Int {
        if section == SettingBackUpSectionCell.settingBackupData.rawValue {
            return self.getSettingBackupData().count
        } else if section == SettingBackUpSectionCell.settingBackupTitle.rawValue {
            return self.getSettingBackupTitleData().count
        } else if section == SettingBackUpSectionCell.settingBackupRule.rawValue {
            return self.getSettingBackupRuleData().count
        } else {
            return self.getSettingBackupMinuteData().count
        }
    }
    
    func item(atIndexPath indexPath: IndexPath) -> SettingBackupData? {
        if indexPath.section == SettingBackUpSectionCell.settingBackupData.rawValue {
            if indexPath.row < self.getSettingBackupData().count {
                return self.getSettingBackupData()[indexPath.row]
            }
        } else if indexPath.section == SettingBackUpSectionCell.settingBackupTitle.rawValue {
            if indexPath.row < self.getSettingBackupTitleData().count {
                return self.getSettingBackupTitleData()[indexPath.row]
            }
        } else if indexPath.section == SettingBackUpSectionCell.settingBackupRule.rawValue {
            if indexPath.row < self.getSettingBackupRuleData().count {
                return self.getSettingBackupRuleData()[indexPath.row]
            }
        } else if indexPath.section == SettingBackUpSectionCell.settingBackupMinute.rawValue {
            if indexPath.row < self.getSettingBackupMinuteData().count {
                return self.getSettingBackupMinuteData()[indexPath.row]
            }
        }
        
        return nil
    }
    
    private func getSettingBackupData() -> [SettingBackupData] {
        return self.backupData
    }
    
    private func getSettingBackupRuleData() -> [SettingBackupData] {
        return self.ruleBackupData
    }
    
    private func getSettingBackupTitleData() -> [SettingBackupData] {
        return self.titleBackupData
    }
    
    private func getSettingBackupMinuteData() -> [SettingBackupData] {
        return self.minuteBackupData
    }
}
