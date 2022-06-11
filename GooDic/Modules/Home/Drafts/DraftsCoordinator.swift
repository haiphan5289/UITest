//
//  DraftsCoordinator.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol DraftsNavigateDelegate {
    func reloadFolders()
}

protocol DraftsNavigateProtocol: ErrorMessageProtocol {
    func toNewDocument(with folderId: FolderId, folder: Folder?)
    func reloadFolders()
}

class DraftsCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    var delegate: DraftsNavigateDelegate?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = DraftsViewController.instantiate(storyboard: .home)
        }
    }
    
    @discardableResult
    func prepare(folder: Folder) -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? DraftsViewController else { return self }
        
        if case .cloud(_) = folder.id {
            let coord = CloudDraftsCoordinator(parentCoord: self)
                .prepare(folder: folder)
            vc.innerVC = coord.viewController as? (MultiSelectionViewProtocol & CloudScreenViewProtocol)
        } else {
            let coord = LocalDraftsCoordinator(parentCoord: self)
            coord.prepare(folder: folder)
            vc.innerVC = coord.viewController as? (MultiSelectionViewProtocol & CloudScreenViewProtocol)
        }
        
        vc.sceneType = .draftsInFolder
        let useCase = DraftsUseCase()
        let viewModel = DraftsViewModel(navigator: self, useCase: useCase, folderId: folder.id, title: folder.name)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension DraftsCoordinator: DraftsNavigateProtocol {
    func reloadFolders() {
        self.delegate?.reloadFolders()
    }
    
    func toNewDocument(with folderId: FolderId, folder: Folder?) {
        if let presentedVC = viewController.presentedViewController {
            presentedVC.dismiss(animated: false) {
                CreationCoordinator(parentCoord: self)
                    .prepare(attachTo: folderId, folder: folder)
                    .presentWithNavigationController()
            }
        } else {
            CreationCoordinator(parentCoord: self)
                .prepare(attachTo: folderId, folder: folder)
                .presentWithNavigationController()
        }
    }
}
