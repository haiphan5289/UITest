//
//  SettingEnviromentalCoordinator.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

protocol SettingEnviromentalNavigateProtocol: ErrorMessageProtocol {
    func toSettingBackup()
}

class SettingEnviromentalCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare() -> SettingEnviromentalCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? SettingEnviromentalViewController else { return self }
        
        vc.sceneType = .settingEnviromental
        let useCase = SettingEnviromentalUseCase()
        let viewModel = SettingEnviromentalViewModel(data: self.createSettingEnviromentalData(), useCase: useCase, navigator: self)

        vc.bindViewModel(viewModel)
        
        return self
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = SettingEnviromentalViewController.instantiate(storyboard: .settingEnviromental)
        }
    }
    
    private func createSettingEnviromentalData() -> [SettingEnviromentalData] {
        let data: [SettingEnviromentalData] = [
            SettingEnviromentalData(title: L10n.SettingEnviromental.AutoCloudSaveCell.title,
                     sceneType: GATracking.Scene.unknown,
                     action: .none),
            SettingEnviromentalData(title: L10n.SettingEnviromental.BackupCell.title,
                     sceneType: GATracking.Scene.backup,
                     action: .openSettingBackup)]
        return data
    }
}

extension SettingEnviromentalCoordinator: SettingEnviromentalNavigateProtocol {
    func toSettingBackup() {
        SettingBackupCoordinator(parentCoord: self)
            .prepare()
            .push()
    }
}
