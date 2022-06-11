//
//  ErrorDeviceResigtrationCoordinator.swift
//  GooDic
//
//  Created by ttvu on 1/14/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

protocol ErrorDeviceRegistrationNavigateProtocol: ErrorMessageProtocol {
    func toDevicesScreen(typeRegister: RouteLogin)
}

class ErrorDeviceRegistrationCoorditator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = ErrorDeviceRegistrationViewController.instantiate(storyboard: .alert)
        }
    }
    
    @discardableResult
    func prepare(typeRegister: RouteLogin, paddingTop: CGFloat = 20) -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? ErrorDeviceRegistrationViewController else { return self }
        
        let useCase = ErrorDeviceRegistrationUseCase()
        let viewModel = ErrorDeviceRegistrationViewModel(useCase: useCase, navigator: self, typeRegister: typeRegister)
        vc.bindViewModel(viewModel)
        vc.setPaddingTop(value: paddingTop)
        
        return self
    }
}

extension ErrorDeviceRegistrationCoorditator: ErrorDeviceRegistrationNavigateProtocol {
    func toDevicesScreen(typeRegister: RouteLogin) {
        RegisterDeviceCoordinator(parentCoord: self)
            .prepare(typeRegister: typeRegister)
            .push()
    }
}
