//
//  BackupDetailCoordinator.swift
//  GooDic
//
//  Created by Vinh Nguyen on 26/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

protocol BackupDetailNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
}

class BackupDetailCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare(document: Document, backupDocument: CloudBackupDocument) -> BackupDetailCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? BackupDetailViewController else { return self }
        
        vc.sceneType = .backupDetail
        let useCase = BackupDetailUseCase()
        let viewModel = BackupDetailViewModel(useCase: useCase, navigator: self, document: document, backupDocument: backupDocument)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = BackupDetailViewController.instantiate(storyboard: .backup)
        }
    }
    
}

extension BackupDetailCoordinator: BackupDetailNavigateProtocol {

}
