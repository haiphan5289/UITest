//
//  RequestPremiumCoodinator.swift
//  GooDic
//
//  Created by Hao Nguyen on 5/24/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol RequestPremiumDelegate {
    func dismissRequestPremium()
}

protocol RequestPremiumNavigateProtocol: ErrorMessageProtocol {
    func toConfirmPremium()
    func toDismiss()
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]?)
    func toForceLogout()
}

class RequestPremiumCoodinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    var delegate: RequestPremiumDelegate?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = RequestPremiumViewController.instantiate(storyboard: .registerPremium)
        }
    }
    
    @discardableResult
    func prepare() -> RequestPremiumCoodinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? RequestPremiumViewController else { return self }
        
        vc.sceneType = .requestPremium
        let useCase = PremiumUseCase()
        let viewModel = RequestPremiumViewModel(navigator: self, useCase: useCase)
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

extension RequestPremiumCoodinator: RequestPremiumNavigateProtocol {
    
    func toConfirmPremium() {
        guard let parentCoord = self.parentCoord else { return }
        self.dismiss(animated: false, completion: {
            let confirmPremiumCoodinator = ConfirmPremiumCoodinator(parentCoord: parentCoord)
            confirmPremiumCoodinator.delegate = self
            confirmPremiumCoodinator
                .prepare()
                .presentInNavigationController()
        })
    }
    
    func toDismiss() {
        self.dismiss(animated: true, completion: {
            self.delegate?.dismissRequestPremium()
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

extension RequestPremiumCoodinator: ConfirmPremiumDelegate {
    func dismissConfirmPremium() {
        self.delegate?.dismissRequestPremium()
    }
}
