//
//  WebCoordinator.swift
//  GooDic
//
//  Created by ttvu on 6/1/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

protocol WebDelegate {
    func dismiss()
}

protocol WebCoordinatorProtocol: ErrorMessageProtocol {
    func moveToPremium()
    func eventDismiss()
}

class WebCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    var delegate: WebDelegate?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare(title: String,
                 url: URL, sceneType: GATracking.Scene = .unknown,
                 cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                 handleLinkBlock: ((URL) -> Bool)? = nil, allowOrientation: UIInterfaceOrientationMask = .all) -> WebCoordinator {
        
        let webView = WebViewController(url: url, cachePolicy: cachePolicy, handleLinkBlock: handleLinkBlock)
        viewController = webView
        
        webView.allowOrientation = allowOrientation
        webView.sceneType = sceneType
        webView.title = title
        webView.hidesBottomBarWhenPushed = true
        let useCase = WebViewUseCase()
        let viewModel = WebViewVM(navigator: self, useCase: useCase)
        webView.viewModel = viewModel
        return self
    }
    
    @discardableResult
    func prepareFeedbackVC(title: String, url: URL, sceneType: GATracking.Scene = .unknown) -> WebCoordinator {
        let webview = FeedbackViewController(url: url)
        viewController = webview
        
        webview.sceneType = sceneType
        webview.title = title
        let useCase = WebViewUseCase()
        let viewModel = WebViewVM(navigator: self, useCase: useCase)
        webview.viewModel = viewModel
        
        return self
    }
    
    @discardableResult
    func prepareNaviWebView(title: String,
                            url: URL,
                            sceneType: GATracking.Scene = .unknown,
                            openFrom: WebViewController.OpenFrom = .otther,
                            handleLinkBlock: ((URL) -> Bool)? = nil) -> WebCoordinator {
        let webview = NaviWebViewController(url: url, handleLinkBlock: handleLinkBlock)
        viewController = webview
        webview.openFrom = openFrom
        
        webview.sceneType = sceneType
        webview.title = title
        let useCase = WebViewUseCase()
        let viewModel = WebViewVM(navigator: self, useCase: useCase)
        webview.viewModel = viewModel
        
        return self
    }
    
    func replace() {
        if let parentVC = self.parentCoord?.viewController,
           let count = parentVC.navigationController?.viewControllers.count, count > 1 {
            parentVC.navigationController?.viewControllers[count - 1] = viewController
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
extension WebCoordinator: WebCoordinatorProtocol {
    func eventDismiss() {
        self.delegate?.dismiss()
    }
    
    
    func moveToPremium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
    }
    
}
