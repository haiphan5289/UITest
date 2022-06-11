//
//  AccountCoordinator.swift
//  GooDic
//
//  Created by ttvu on 11/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import GooidSDK

enum RouteLogin {
    case login
    case forceLogout
    case cloudFolderSelection
    case cloudFolder
    case cloudDraft
    case menu
    case app
    case tutorial
    case cloud
    case detecStatusUser
    case detectStatusUserWhenStartApp
    
    var isForceDetectDevices: Bool {
        switch self {
        case .detecStatusUser, .detectStatusUserWhenStartApp:
            return true
        default:
            return false
        }
    }

    var screenName: String {
        switch self {
        case .cloudDraft:
            return L10n.ScreenName.screenDraft
        case .cloudFolder:
            return L10n.ScreenName.screenFolder
        case .menu:
            return L10n.ScreenName.screenMenu
        case .cloudFolderSelection:
            return L10n.ScreenName.screenCloudFolderSelection
        case .forceLogout:
            return L10n.ScreenName.screenForceLogout
        case .login:
            return L10n.ScreenName.screenLogin
        default:
            return ""
        }
    }
}

protocol LoginNavigateProtocol: ErrorMessageProtocol {
    var viewcontroller: UIViewController { get }
    var routeLoginNavi: RouteLogin { get }
    func toRegisterDevice()
    func popViewController()
    func toGooLoginView()
    func moveToRegisterScreenWhenTapRegister()
    func showMessageCode(_ code: Int) -> Observable<Void>
    func showMessageErrorCodeList(_ code: String) -> Observable<Void>
    func toForceLogout()
    func moveToRegister(isRegister: Bool) -> Observable<Void>
    func toListDeviceWithCaseOverLimit()
}

class LoginCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    private var routeLogin: RouteLogin = .login
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = LoginViewController.instantiate(storyboard: .login)
        }
    }
    
    @discardableResult
    func prepare(routeLogin: RouteLogin, sceneType: GATracking.Scene = .openLoginScreen) -> LoginCoordinator {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? LoginViewController else { return self }
        vc.sceneType = sceneType
        vc.routeLogin = routeLogin
        let useCase = LoginUseCase()
        let viewModel = LoginViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        switch routeLogin {
        case .menu:
            vc.hidesBottomBarWhenPushed = true
        default:
            break
        }
        
        self.routeLogin = routeLogin
        
        makeCosmetic()
        
        return self
    }
    
    private func makeCosmetic() {
        UIWindow.key?.tintColor = Asset.textPrimary.color
    }
    
    func startInNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.navigationBar.tintColor = Asset.textPrimary.color
        
        UIWindow.key?.rootViewController = nc
    }
    
    func presentInNavigationController() {
        guard let parentVC = parentCoord?.viewController else { return }
        
        let nc = BaseNavigationController(rootViewController: viewController)
        
        parentVC.present(nc, animated: true, completion: nil)
    }
}

extension LoginCoordinator: LoginNavigateProtocol {
    var viewcontroller: UIViewController {
        return self.parentCoord?.viewController ?? self.viewcontroller
    }
    
    var routeLoginNavi: RouteLogin {
        return self.routeLogin
    }
    
    func toGooLoginView() {
        switch self.routeLogin {
        case .menu:
            self.pop()
        default:
            MainCoordinator(parentCoord: self)
                .prepare()
                .start()
        }
    }
    
    func toListDeviceWithCaseOverLimit() {
        switch self.routeLogin {
        case .app, .tutorial:
            RegisterDeviceCoordinator(parentCoord: self)
                .prepare(typeRegister: .detectStatusUserWhenStartApp, isRemoveLoginScreen: true)
                .startInNavigationController()
        default:
            RegisterDeviceCoordinator(parentCoord: self)
                .prepare(typeRegister: .detecStatusUser, isRemoveLoginScreen: true)
                .pushToRegister()
        }
    }
    
    func moveToRegister(isRegister: Bool) -> Observable<Void> {
        switch self.routeLogin {
        case .app, .login, .tutorial:
            if isRegister {
                MainCoordinator(parentCoord: self)
                    .prepare()
                    .start()
            } else {
                RegisterDeviceCoordinator(parentCoord: self)
                    .prepare(typeRegister: self.routeLogin, isRemoveLoginScreen: true)
                    .startInNavigationController()
            }
        default:
            if isRegister {
                self.pop(animated: false)
            } else {
                RegisterDeviceCoordinator(parentCoord: self)
                    .prepare(typeRegister: .menu, isRemoveLoginScreen: true)
                    .pushToRegister()
            }
        }
        return Observable.just(())
    }
    
    func toRegisterDevice() {
        switch  self.routeLogin {
        case .app, .login, .tutorial:
            RegisterDeviceCoordinator(parentCoord: self)
                .prepare(typeRegister: self.routeLogin)
                .startInNavigationController()
        default:
            self.pop()
        break
        }
    }
    func moveToRegisterScreenWhenTapRegister() {
        switch self.routeLogin {
        case .app, .login, .tutorial:
            RegisterDeviceCoordinator(parentCoord: self)
                .prepare(typeRegister: self.routeLogin)
                .startInNavigationController()
        default:
            RegisterDeviceCoordinator(parentCoord: self)
                .prepare(typeRegister: .cloud, isRemoveLoginScreen: true)
                .pushToRegister()
        }
    }
    
    func popViewController() {
        self.pop()
    }
    
    func showMessageListDevice(_ message: String) -> Observable<Void> {
        guard let parentVC = self.parentCoord?.viewController else {
            return Observable.empty()
        }
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        return UIAlertController
            .present(in: parentVC,
                     title: "",
                     message: message,
                     style: .alert,
                     actions: actions)
            .mapToVoid()
    }
    
    func showMessageCode(_ code: Int) -> Observable<Void> {
        showMessageList(code,
                    message: L10n.Server.Error.Other.message,
                    hyperlink: L10n.Server.Error.Other.hyperlink,
                    link: GlobalConstant.errorInfoURL)
    }
    
    private func showMessageList(_ code: Int, message: String, hyperlink: String, link: String) -> Observable<Void> {
        guard let parentVC = self.parentCoord?.viewController else {
            return Observable.empty()
        }
        let errorCode = String(format: "%2d", code)
        let title = L10n.Server.Error.Other.title(errorCode)
        
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        let attributedString = NSMutableAttributedString(string: message, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)
        ])
        
        if let linkRange = message.range(of: hyperlink) {
            let start = message.distance(from: message.startIndex, to: linkRange.lowerBound)
            let length = message.distance(from: linkRange.lowerBound, to: linkRange.upperBound)
            attributedString.addAttribute(.link, value: link, range: NSRange(location: start, length: length))
        }
        
        return UIAlertController
            .present(in: parentVC,
                     title: title,
                     clickableMessage: attributedString,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: nil)
            .mapToVoid()
    }
    func showMessageErrorCodeList(_ code: String) -> Observable<Void> {
        showMessageErrorCodeList(code,
                    message: L10n.Server.Error.Other.message,
                    hyperlink: L10n.Server.Error.Other.hyperlink,
                    link: GlobalConstant.errorInfoURL)
    }
    
    private func showMessageErrorCodeList(_ code: String, message: String, hyperlink: String, link: String) -> Observable<Void> {
        guard let parentVC = self.parentCoord?.viewController else {
            return Observable.empty()
        }
        let title = L10n.Server.Error.Other.title(code)
        
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        let attributedString = NSMutableAttributedString(string: message, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)
        ])
        
        if let linkRange = message.range(of: hyperlink) {
            let start = message.distance(from: message.startIndex, to: linkRange.lowerBound)
            let length = message.distance(from: linkRange.lowerBound, to: linkRange.upperBound)
            attributedString.addAttribute(.link, value: link, range: NSRange(location: start, length: length))
        }
        
        return UIAlertController
            .present(in: parentVC,
                     title: title,
                     clickableMessage: attributedString,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: nil)
            .mapToVoid()
    }
    func toForceLogout() {
        RegistrationLogoutCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
}
