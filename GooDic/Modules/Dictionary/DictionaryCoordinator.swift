//
//  DictionaryCoordinator.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

protocol DictionaryNavigateProtocol: class, ErrorMessageProtocol, AppManagerProtocol {
    func dismiss()
    func toResultWebView(url: URL)
    func toAdvanced()
}

class DictionaryCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = DictionaryViewController.instantiate(storyboard: .dictionary)
        }
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? DictionaryViewController else { return self }
        
        vc.sceneType = .search
        let useCase = DictionaryUseCase()
        let viewModel = DictionaryViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    @discardableResult
    func prepareInDraft() -> DictionaryCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? DictionaryViewController else { return self }
        
        vc.sceneType = .searchInDraft
        vc.title = L10n.Dictionary.title
        vc.dismissButton = UIBarButtonItem.createDismissButton()
        
        let useCase = DictionaryUseCase()
        let viewModel = DictionaryViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func presentInNavigationController() {
        guard let parentVC = parentCoord?.viewController else { return }
        
        let transitioningProxy = CardPresentationProxy()
        
        let nc = BaseNavigationController(rootViewController: viewController)
        viewController.setupNavigationTitle(type: .dictionary)
        
        let wrappedVC = ContainerViewController(root: nc)
        wrappedVC.transitioningDelegate = transitioningProxy
        wrappedVC.modalPresentationStyle = .custom

        parentVC.present(wrappedVC, animated: true, completion: nil)
    }
}

extension DictionaryCoordinator: DictionaryNavigateProtocol {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func toResultWebView(url: URL) {
        guard let currentSceneType = (viewController as? BaseViewController)?.sceneType else { return }
        let sceneType: GATracking.Scene = currentSceneType == .search ? .searchResults : .searchResultslnDraft
        
        WebCoordinator(parentCoord: self)
            .prepareNaviWebView(title: L10n.Dictionary.Result.title, url: url, sceneType: sceneType, openFrom: .dictionary)
            .presentInNavigationController(orientationMask: .all)
    }
    
    func toAdvanced() {
        AdvancedDictionaryCoordinator(parentCoord: self)
            .prepare()
            .push()
    }
}
