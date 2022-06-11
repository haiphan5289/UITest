//
//  AccountInfoCoodinator.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/1/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol AccountInfoNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func toLogoutConfirmation() -> Observable<Bool>
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]?)
    func toExternalWebView(url: URL)
}

class AccountInfoCoodinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = AccountInfoViewController.instantiate(storyboard: .accountInfo)
        }
    }
    
    @discardableResult
    func prepare() -> AccountInfoCoodinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? AccountInfoViewController else { return self }
        
        vc.sceneType = .accountInfo
        let useCase = AccountInfoUseCase()
        let viewModel = AccountInfoViewModel(useCase: useCase, navigator: self)
        vc.bindViewModel(viewModel)
        return self
    }
}

extension AccountInfoCoodinator: AccountInfoNavigateProtocol {
    func toLogoutConfirmation() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Account.LogoutConfirmation.cancel, style: .default),
            .action(title: L10n.Account.LogoutConfirmation.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == L10n.Account.LogoutConfirmation.ok {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.cancel.color, forKey: "titleTextColor")
            }
        }
        
        return UIAlertController
            .present(in: viewController,
                     title: L10n.Account.LogoutConfirmation.title,
                     message: L10n.Account.LogoutConfirmation.message,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
    
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]? = nil) {
        
        let handleLinkBlock = { (url: URL) -> Bool in
            var coord: AppCoordinator? = nil
            if #available(iOS 13.0, *) {
                coord = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appCoordinator
            } else {
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    coord = appDelegate.appCoordinator
                }
            }
            guard let appURI = AppURI(rawValue: url.absoluteString) else {
                return false
            }
            switch appURI {
            case .registerDevice:
                RegisterDeviceCoordinator(parentCoord: self)
                    .prepare(typeRegister: .menu)
                    .push()
            case .homeCloud:
                coord?.mainCoord?.toDynamicView(appURI: appURI, entryAction: .schemeUriNormal)
            default:
                if url.absoluteString.contains("support.apple.com") {
                    GATracking.tap(.tapIosUnregister)
                } else if url.absoluteString.contains("support.google.com") {
                    GATracking.tap(.tapAndroidUnregister)
                } else {
                    GATracking.tap(.tapGooStorePcUnregister)
                }
                return false
            }
            return false
        }
        WebCoordinator(parentCoord: self)
            .prepare(title: title, url: url, sceneType: sceneType, cachePolicy: cachePolicy, handleLinkBlock: handleLinkBlock, allowOrientation: .all)
            .push()
    }
    
    func toExternalWebView(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
