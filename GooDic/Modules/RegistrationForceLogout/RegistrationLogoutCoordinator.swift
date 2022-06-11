//
//  RegistrationLogoutCoordinator.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol RegistrationLogoutNavigateProtocol: ErrorMessageProtocol {
    var viewcontroller: UIViewController { get }
    func toGooLoginView()
    func popViewController()
    func toRegisterDevice()
    func toErrorServerAlert(title: String ,msg: String) -> Observable<Bool>
}

class RegistrationLogoutCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = RegistrationLogoutViewController.instantiate(storyboard: .registrationLogout)
        }
    }
    
    func prepare(sceneType: GATracking.Scene = .openForceLogoutScreen) -> RegistrationLogoutCoordinator {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? RegistrationLogoutViewController else { return self }
        vc.sceneType = sceneType
        let useCase = RegistrationLogoutUseCase()
        let viewModel = RegistrationLogoutViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
    func presentWithNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.modalPresentationStyle = .fullScreen
        
        parentCoord?.viewController.present(nc, animated: true, completion: nil)
    }
}

extension RegistrationLogoutCoordinator: RegistrationLogoutNavigateProtocol {
    var viewcontroller: UIViewController {
        return self.viewController
    }
    func toGooLoginView() {
        MainCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    func popViewController() {
        self.pop()
    }
    func toRegisterDevice() {
        RegisterDeviceCoordinator(parentCoord: self)
            .prepare(typeRegister: .forceLogout)
            .startInNavigationController()
    }
    func toErrorServerAlert(title: String ,msg: String) -> Observable<Bool> {
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
}

