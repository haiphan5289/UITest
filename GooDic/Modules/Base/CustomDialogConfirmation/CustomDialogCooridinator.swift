//
//  NamingCoordinator.swift
//  GooDic
//
//  Created by ttvu on 12/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol CustomDialogNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    
}

class CustomDialogCoordinator: CoordinateProtocol, CustomDialogNavigateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = CustomDialogViewController.init(nibName: "CustomDialogViewController", bundle: nil)
        }
    }
    
    @discardableResult
    func prepare() -> CustomDialogCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? CustomDialogViewController else { return self }
        
        let useCase = CustomDialogUseCase()
        let viewModel = CustomDialogViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }

    func show() {
        guard let parentVC = parentCoord?.viewController else { return }
        
        //Present
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        parentVC.present(viewController, animated: true, completion: nil)
    }
}

extension CustomDialogCoordinator: NamingNavigateProtocol {

}
