//
//  ConfirmPremiumCoodinator.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/2/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

protocol ConfirmPremiumDelegate {
    func dismissConfirmPremium()
}

protocol ConfirmPremiumNavigateProtocol: ErrorMessageProtocol {
    func toDismiss()
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]?)
    func toForceLogout()
}

class ConfirmPremiumCoodinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    var delegate: ConfirmPremiumDelegate?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = ConfirmPremiumViewController.instantiate(storyboard: .registerPremium)
        }
    }
    
    @discardableResult
    func prepare() -> ConfirmPremiumCoodinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? ConfirmPremiumViewController else { return self }
        
        vc.sceneType = .confirmPremium
        let useCase = PremiumUseCase()
        let viewModel = ConfirmPremiumViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
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

extension ConfirmPremiumCoodinator: ConfirmPremiumNavigateProtocol {
    func toDismiss() {
        self.dismiss(animated: true, completion: {
            self.delegate?.dismissConfirmPremium()
        })
    }
    
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]? = nil) {
        var handleLinkBlock: ((URL) -> Bool)? = nil
        if let internalLinkDatas = internalLinkDatas {
            handleLinkBlock = { (url: URL) -> Bool in
                if let data = internalLinkDatas.first(where: { $0.ulr == url.absoluteString }) {
                    self.toWebView(url: url, cachePolicy: data.cachePolicy, title: data.title, sceneType: data.sceneType)
                    return true
                }

                return false
            }
        }

        WebCoordinator(parentCoord: self)
            .prepare(title: title, url: url, sceneType: sceneType, cachePolicy: cachePolicy, handleLinkBlock: handleLinkBlock, allowOrientation: .all)
            .push()
    }
    
    func toForceLogout() {
        RegistrationLogoutCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
}
