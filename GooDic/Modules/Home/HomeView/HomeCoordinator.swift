//
//  HomeCoordinator.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

protocol HomeNavigateProtocol: ErrorMessageProtocol, AppManagerProtocol {
    func toNewDocument(with folderId: FolderId, isHome: Bool)
    func toCloudTab()
    func transition(uri: String?)
}

class HomeCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        guard let vc = viewController as? HomeViewController else { return self }
        
        vc.sceneType = .openHomeScreen
        
        let localCoord = LocalDraftsCoordinator(parentCoord: self)
        localCoord.prepare()
        vc.localVC = localCoord.viewController as? LocalDraftsViewController
        
        let cloudCoord = CloudDraftsCoordinator(parentCoord: self)
        cloudCoord.prepare(folder: nil)
        vc.cloudVC = cloudCoord.viewController as? CloudDraftsViewController
        
        let useCase = HomeUseCase()
        let viewModel = HomeViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension HomeCoordinator: HomeNavigateProtocol {
    func toNewDocument(with folderId: FolderId, isHome: Bool) {
        CreationCoordinator(parentCoord: self)
            .prepare(attachTo: folderId, folder: nil)
            .presentWithNavigationController()
    }
    
    func toCloudTab() {
        if let nc = viewController.navigationController, nc.viewControllers.count > 1 {
            nc.popToRootViewController(animated: false)
        }
        
        if let viewController = viewController as? HomeViewController {
            viewController.changeSegment(openCloudSegment: true)
        }
    }
    
    func transition(uri: String?) {
        guard let uri = uri else { return }
        var coord: AppCoordinator? = nil
        if #available(iOS 13.0, *) {
            coord = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appCoordinator
        } else {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                coord = appDelegate.appCoordinator
            }
        }
        
        coord?.toDynamicView(description: uri, entryAction: .topBanner)
    }
}
