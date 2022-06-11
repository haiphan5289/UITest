//
//  DrawPresentCoordinator.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import UIKit

protocol DrawPresentDelegate {
    func dismissSort()
    func updateSort(sort: SortModel)
}

protocol DrawPresentNavigateProtocol {
    func toSort(openfromScreen: SortVM.openfromScreen, sortModel: SortModel, folder: Folder?)
    func dismissDraw()
}

class DrawPresentCoodinator: CoordinateProtocol {
    
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    var delegate: DrawPresentDelegate?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = DrawPresentVC.instantiate(storyboard: .draw)
        }
    }
    
    @discardableResult
    func prepare(openfromScreen: SortVM.openfromScreen, sortModel: SortModel, folder: Folder?) -> DrawPresentCoodinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? DrawPresentVC else { return self }
        
        let useCase = DrawPresenttUseCase()
        let viewModel = DrawPresentVM(navigator: self, useCase: useCase, openfromScreen: openfromScreen, sortModel: sortModel, folder: folder)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func presentInNavigationController(duration: TimeInterval = 0.3, orientationMask: UIInterfaceOrientationMask? = nil) {
        let nc = BaseNavigationController(rootViewController: viewController)
        let wrappedVC = ContainerViewController(root: nc)
        wrappedVC.modalPresentationStyle = .overFullScreen
        wrappedVC.modalTransitionStyle = .crossDissolve
        
        self.parentCoord?.viewController.present(wrappedVC, animated: true, completion: nil)
    }
    
    
}

extension DrawPresentCoodinator: DrawPresentNavigateProtocol {
    func dismissDraw() {
        self.dismiss(animated: true) {
            self.delegate?.dismissSort()
        }
    }
    
    func toSort(openfromScreen: SortVM.openfromScreen, sortModel: SortModel, folder: Folder?) {
        let sort = SortCoodinator(parentCoord: self)
        sort.delegate = self
        sort.prepare(openfromScreen: openfromScreen, sortModel: sortModel, folder: folder).presentInNavigationController()
    }
}
extension DrawPresentCoodinator: SortDelegate {
    func dismissSort() {
        self.dismiss(animated: true) {
            self.delegate?.dismissSort()
        }
    }
    
    func updateSort(sort: SortModel) {
        self.delegate?.updateSort(sort: sort)
    }
}
