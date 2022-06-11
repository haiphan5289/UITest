//
//  CoordinateProtocol.swift
//  GooDic
//
//  Created by ttvu on 10/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

protocol CoordinateProtocol {
    var parentCoord: CoordinateProtocol? { get set }
    
    // NOTE: always use weak instance to avoid a retain cycle
    var viewController: UIViewController! { get }
    
    @discardableResult
    func prepare() -> CoordinateProtocol // setup dependencies: view, viewModel, useCase, navigator
}

extension CoordinateProtocol {
    typealias Completion = (()->Void)
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        return self
    }
    
    func start() {
        UIWindow.key?.rootViewController = viewController
    }
    
    func push(animated: Bool = true) {
        parentCoord?.viewController.navigationController?.pushViewController(viewController, animated: animated)
    }
    
    func pop(animated: Bool = true) {
        viewController.navigationController?.popViewController(animated: animated)
    }
    
    func present(animated: Bool = true, completion: Completion? = nil) {
        parentCoord?.viewController.present(viewController, animated: animated, completion: completion)
    }
    
    func dismiss(animated: Bool = true, completion: Completion? = nil) {
        viewController.dismiss(animated: animated, completion: completion)
    }
}
