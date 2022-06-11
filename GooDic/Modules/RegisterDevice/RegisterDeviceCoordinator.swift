//
//  RegisterDeviceCoordiantor.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.

import UIKit
import RxSwift

protocol RegisterDeviceNavigateProtocol: ErrorMessageProtocol {
    func toGooLoginView()
    func popToViewController()
    func toErrorAlert(title: String, msg: String) -> Observable<Bool>
    func toForceLogout()
    func toRemoveLogin() -> Observable<Void>
}

class RegisterDeviceCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = RegisterDeviceViewController.instantiate(storyboard: .registerDevice)
        }
    }
    
    func prepare(typeRegister: RouteLogin, isRemoveLoginScreen: Bool? = false) -> RegisterDeviceCoordinator {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? RegisterDeviceViewController else { return self }
        vc.typeRegisterDevice = typeRegister
        vc.isRemoveLoginScreen = isRemoveLoginScreen ?? false
        vc.hidesBottomBarWhenPushed = true
        let useCase = RegisterDeviceUseCase.init()
        let viewModel = RegisterDeviceVM(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
    func startInNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.navigationBar.tintColor = Asset.textPrimary.color
        
        UIWindow.key?.rootViewController = nc
    }
    
    func pushToRegister() {
        if (self.parentCoord?.viewController.navigationController != nil) {
            self.push(animated: false)
        } else {
            parentCoord?.parentCoord?.viewController.navigationController?.pushViewController(viewController, animated: false)
        }
    }

}

extension RegisterDeviceCoordinator: RegisterDeviceNavigateProtocol {
    
    func toGooLoginView() {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? RegisterDeviceViewController else { return }
        
        switch vc.typeRegisterDevice {
        case .app, .login, .tutorial, .detectStatusUserWhenStartApp:
            MainCoordinator(parentCoord: self)
                .prepare()
                .start()
        default:
            self.pop()
        }
        
    }
    func popToViewController() {
        self.pop()
    }
    func toErrorAlert(title: String, msg: String) -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        return UIAlertController
            .present(in: viewController,
                     title: title,
                     message: msg,
                     style: .alert,
                     actions: actions)
            .map({ $0 == 0 })
    }
    func toForceLogout() {
        RegistrationLogoutCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    func toRemoveLogin() -> Observable<Void> {
        //remove login screen when move from menu to register
        guard let navigationController = self.viewController.navigationController else { return Observable.empty() }
        guard let vc = viewController as? RegisterDeviceViewController else { return Observable.empty() }
        
        guard vc.isRemoveLoginScreen else { return Observable.empty() }
        var navigationArray = navigationController.viewControllers // To get all UIViewController stack as Array
        navigationArray.enumerated().forEach { (element) in
            if element.element.isKind(of: LoginViewController.self) {
                navigationArray.remove(at: element.offset)
            }
        }
        self.viewController.navigationController?.viewControllers = navigationArray
        return Observable.just(())
    }
}


