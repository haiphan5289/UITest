//
//  FolderBrowserCoordinator.swift
//  GooDic
//
//  Created by ttvu on 9/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol FolderBrowserNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol, AppManagerProtocol {
    func dismiss()
    func toCreationFolder(createCloudFolderAsDefault value: Bool, valueIndex: Double?) -> Observable<UpdateFolderResult>
    func toDraftList(in folder: Folder?)
}

class FolderBrowserCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = FolderBrowserViewController.instantiate(storyboard: .folder)
        }
    }
    
    @discardableResult
    func prepare() -> FolderBrowserCoordinator {
        guard let vc = viewController as? FolderBrowserViewController else { return self }
        
        let localCoord = LocalFoldersCoordinator(parentCoord: self)
        localCoord.prepare()
        vc.localVC = localCoord.viewController as? FoldersScreenProtocol
        vc.viewModelLocal = localCoord.getViewModelLocal()
        
        
        let cloudCoord = CloudFoldersCoordinator(parentCoord: self)
        cloudCoord.prepare()
        vc.cloudVC = cloudCoord.viewController as? (CloudScreenViewProtocol & FoldersScreenProtocol)
        vc.viewModelCloud = cloudCoord.getViewModelCloud()
        
        vc.sceneType = .folder
        let viewModel = FolderBrowserViewModel(navigator: self)
        
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    @discardableResult
    func prepare(delegate: PublishSubject<SelectionResult>, drafts: [Document], draftOrigin: [Document]) -> FolderBrowserCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? FolderBrowserViewController else { return self }
        
        let localCoord = LocalFolderSelectionCoordinator(parentCoord: self)
        localCoord.prepare(delegate: delegate, drafts: drafts, draftOrigin: draftOrigin)
        vc.localVC = localCoord.viewController as? FoldersScreenProtocol
        vc.viewModelLocationSelection = localCoord.getViewModelLocal()
        
        let cloudCoord = CloudFolderSelectionCoordinator(parentCoord: self)
        cloudCoord.prepare(delegate: delegate, drafts: drafts)
        vc.cloudVC = cloudCoord.viewController as? (CloudScreenViewProtocol & FoldersScreenProtocol)
        
        let isCloudDraft = drafts.first?.onCloud ?? false
        
        vc.sceneType = .selectDestinationFolder
        let viewModel = FolderBrowserViewModel(navigator: self, delegate: delegate, isMoveCloudDraft: isCloudDraft)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func presentInNavigationController() {
        guard let parentVC = parentCoord?.viewController else { return }
        
        let transitioningProxy = CardPresentationProxy()
        
        let nc = BaseNavigationController(rootViewController: viewController)
        viewController.setupNavigationTitle(type: .folderBrowser)
        
        let wrappedVC = ContainerViewController(root: nc)
        wrappedVC.transitioningDelegate = transitioningProxy
        wrappedVC.modalPresentationStyle = .custom
        
        parentVC.present(wrappedVC, animated: true, completion: nil)
    }
}

extension FolderBrowserCoordinator: FolderBrowserNavigateProtocol {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func toCreationFolder(createCloudFolderAsDefault value: Bool, valueIndex: Double?) -> Observable<UpdateFolderResult> {
        let delegate = PublishSubject<UpdateFolderResult>()
        
        NamingCoordinator(parentCoord: self)
            .prepare(delegate: delegate,
                     title: L10n.Folder.CreationAlert.title,
                     message: L10n.Folder.CreationAlert.message,
                     confirmButtonName: L10n.Folder.CreationAlert.ok,
                     folder: nil,
                     createCloudFolderAsDefault: value,
                     valueIndex: valueIndex)
            .show()
        
        return delegate
            .asObservable()
    }
    
    func toDraftList(in folder: Folder?) {
        let coord = DraftsCoordinator(parentCoord: self)
        
        if let nc = viewController.navigationController, nc.viewControllers.count > 1 {
            nc.popToRootViewController(animated: false)
        }
        
        let vc = viewController as! FolderBrowserViewController
        
        if let folder = folder {
            vc.changeSegment(openCloudSegment: folder.onCloud)
            
            coord.prepare(folder: folder)
                .push()
        } else {
            vc.changeSegment(openCloudSegment: false)
            
            coord.prepare(folder: Folder(name: L10n.Folder.uncategorized, id: .local(""), manualIndex: nil, hasSortManual: false))
                .push()
        }
    }
}
