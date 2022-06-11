//
//  BackupListCoordinator.swift
//  GooDic
//
//  Created by Vinh Nguyen on 25/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit


protocol BackupListNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func toBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument)
}

class BackupListCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare(document: Document) -> BackupListCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? BackupListViewController else { return self }
        
        vc.sceneType = .backupList
        let useCase = BackupListUseCase()
        let viewModel = BackupListViewModel(useCase: useCase, navigator: self, document: document)

        vc.bindViewModel(viewModel)
        
        return self
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = BackupListViewController.instantiate(storyboard: .backup)
        }
    }
    
    func presentInNavigationController(duration: TimeInterval = 0.3, orientationMask: UIInterfaceOrientationMask? = nil) {
        let cardProxy = CardPresentationProxy()
        
        let nc = BaseNavigationController(rootViewController: viewController)
        let wrappedVC = ContainerViewController(root: nc)
        wrappedVC.customOrientationMask = orientationMask
        wrappedVC.transitioningDelegate = cardProxy
        wrappedVC.modalPresentationStyle = .custom

        self.parentCoord?.viewController.present(wrappedVC, animated: true, completion: nil)
    }
}

extension BackupListCoordinator: BackupListNavigateProtocol {
    func toBackupDraftDetail(document: Document, backupDocument: CloudBackupDocument) {
        BackupDetailCoordinator(parentCoord: self)
            .prepare(document: document, backupDocument: backupDocument)
            .push()
    }
    
    func toReferenceView(_ document: Document) {
        let vc = ReferenceViewController.instantiate(storyboard: .home)
        vc.sceneType = .reference
        vc.document = document
        
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
