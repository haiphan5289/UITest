//
//  AdvancedDictionaryCoordinator.swift
//  GooDic
//
//  Created by haiphan on 10/11/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol AdvancedDictionaryNavigateProtocol: ErrorMessageProtocol {
    func dismissView(action: AdvancedDictionaryVC.Action)
    func moveToPremium()
    func toResultWebView(url: URL)
    func eventDismisss() -> Observable<Void>
}

class AdvancedDictionaryCoordinator: CoordinateProtocol {
    
    var parentCoord: CoordinateProtocol?
    var webCoordinate: WebCoordinator?
    weak var viewController: UIViewController!
    weak var wrappedVC: UIViewController!
    private let eventDissmiss: PublishSubject<Void> = PublishSubject.init()
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = AdvancedDictionaryVC.instantiate(storyboard: .advancedDictionary)
        }
    }
    
    func prepare() -> AdvancedDictionaryCoordinator {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? AdvancedDictionaryVC else { return self }
        let useCase = AdvancedDictionaryUseCase()
        let viewModel = AdvancedDictionaryVM(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        vc.hidesBottomBarWhenPushed = true
        vc.rightSafeArea = parentCoord?.viewController.view.safeAreaInsets.right ?? 0
        vc.leftSafeArea = parentCoord?.viewController.view.safeAreaInsets.left ?? 0
        
        return self
    }
    
    func prepareInDraft() -> AdvancedDictionaryCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? AdvancedDictionaryVC else { return self }
        
        vc.sceneType = .searchInDraft
        vc.title = L10n.Dictionary.title
        vc.dismissButton = UIBarButtonItem.createDismissButton()
        
        let useCase = AdvancedDictionaryUseCase()
        let viewModel = AdvancedDictionaryVM(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func presentInNavigationController() {
        guard let parentVC = parentCoord?.viewController else { return }

        let transitioningProxy = CardPresentationProxy()

        let nc = BaseNavigationController(rootViewController: viewController)
        viewController.setupNavigationTitle(type: .advanceDictionary)

        let wrappedVC = ContainerViewController(root: nc)
        wrappedVC.transitioningDelegate = transitioningProxy
        wrappedVC.modalPresentationStyle = .custom

        parentVC.present(wrappedVC, animated: true, completion: nil)
    }
}

extension AdvancedDictionaryCoordinator: AdvancedDictionaryNavigateProtocol {
    func eventDismisss() -> Observable<Void> {
        return self.eventDissmiss.asObservable()
    }
    
    func dismissView(action: AdvancedDictionaryVC.Action) {
        switch  action {
        case .dismiss:
            self.dismiss(animated: true, completion: nil)
        case .pop:
            self.pop()
        }
    }
    
    func toResultWebView(url: URL) {
        guard let currentSceneType = (viewController as? BaseViewController)?.sceneType else { return }
        let sceneType: GATracking.Scene = currentSceneType == .unknown ? .searchResults : .searchResultslnDraft
        
        self.webCoordinate =  WebCoordinator(parentCoord: self)
            .prepareNaviWebView(title: L10n.Dictionary.Result.title, url: url, sceneType: sceneType, openFrom: .dictionary)
        self.webCoordinate?.presentInNavigationController(orientationMask: .all)
        self.webCoordinate?.delegate = self
    }
    
    func moveToPremium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
    }
}
extension AdvancedDictionaryCoordinator: WebDelegate {
    func dismiss() {
        self.eventDissmiss.onNext(())
    }
}
