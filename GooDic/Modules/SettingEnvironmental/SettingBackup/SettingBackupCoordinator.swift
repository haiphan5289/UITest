//
//  SettingBackupCoordinator.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

protocol SettingBackupNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
}

class SettingBackupCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare() -> SettingBackupCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? SettingBackupViewController else { return self }
        
        vc.sceneType = .settingBackup
        let useCase = SettingBackupUseCase()
        let viewModel = SettingBackupViewModel(
            backupData: self.createSettingBackupData(),
            ruleBackupData: self.createSettingBackupRuleData(),
            titleBackupData: self.createSettingBackupTitleData(),
            minuteBackupData: self.createSettingBackupMinuteData(),
            useCase: useCase,
            navigator: self)

        vc.bindViewModel(viewModel)
        
        return self
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = SettingBackupViewController.instantiate(storyboard: .settingEnviromental)
        }
    }
    
    private func createSettingBackupData() -> [SettingBackupData] {
        let data: [SettingBackupData] = [
            SettingBackupData(
                title: L10n.SettingBackup.BackupCreationCell.titleBackupOnOrOff,
                content: L10n.SettingBackup.BackupCreationCell.contentBackupOnOrOff,
                action: .isBackup)
        ]
        return data
    }
    
    private func createSettingBackupRuleData() -> [SettingBackupData] {
        let data: [SettingBackupData] = [
            SettingBackupData(
                title: L10n.SettingBackup.BackupCreationRuleCell.titleBackupManual,
                content: L10n.SettingBackup.BackupCreationRuleCell.contentBackupManual,
                action: .isManualSaveBackup),
            SettingBackupData(
                title: L10n.SettingBackup.BackupCreationRuleCell.titleBackupRegular,
                content: L10n.SettingBackup.BackupCreationRuleCell.contentBackupRegular,
                action: .isPeriodicBackup)
        ]
        return data
    }
    
    private func createSettingBackupTitleData() -> [SettingBackupData] {
        let data: [SettingBackupData] = [
            SettingBackupData(
                title: L10n.SettingBackup.BackupCreationRuleTitleCell.title,
                content: "",
                action: .none)
        ]
        return data
    }
    
    private func createSettingBackupMinuteData() -> [SettingBackupData] {
        let data: [SettingBackupData] = [
            SettingBackupData(
                title: SettingBackupMinute.five.text,
                content: "",
                action: .isSelectMinute),
            SettingBackupData(
                title: SettingBackupMinute.ten.text,
                content: "",
                action: .isSelectMinute),
            SettingBackupData(
                title: SettingBackupMinute.fifteen.text,
                content: "",
                action: .isSelectMinute)
        ]
        return data
    }
}

extension SettingBackupCoordinator: SettingBackupNavigateProtocol {

}
