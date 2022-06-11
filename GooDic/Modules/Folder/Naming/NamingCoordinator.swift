//
//  NamingCoordinator.swift
//  GooDic
//
//  Created by ttvu on 12/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol NamingNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    
}

class NamingCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = NamingViewController.init(nibName: "NamingViewController", bundle: nil)
        }
    }
    
    @discardableResult
    func prepare(delegate: PublishSubject<UpdateFolderResult>,
                 title: String,
                 message: String,
                 confirmButtonName: String,
                 folder: Folder?,
                 createCloudFolderAsDefault: Bool = false,
                 valueIndex: Double?) -> NamingCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? NamingViewController else { return self }
        
        let useCase = NamingUseCase()
        let viewModel = NamingViewModel(title: title,
                                        message: message,
                                        confirmButtonName: confirmButtonName,
                                        folder: folder,
                                        createCloudFolderAsDefault: createCloudFolderAsDefault,
                                        navigator: self,
                                        useCase: useCase,
                                        valueIndex: valueIndex,
                                        delegate: delegate)
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

extension NamingCoordinator: NamingNavigateProtocol {

}
