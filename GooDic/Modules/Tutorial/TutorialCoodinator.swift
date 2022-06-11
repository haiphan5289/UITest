//
//  TutorialCoodinator.swift
//  GooDic
//
//  Created by ttvu on 6/1/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol TutorialNavigateProtocol {
    func toLogin()
    func toHome()
    func moveToRegisterPremium()
    var isDismissRegisterPremium: PublishSubject<Bool> { get }
}

class TutorialCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    private let isDismissRegisterPremiumOb: PublishSubject<Bool> = PublishSubject.init()
    
    
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = TutorialViewController.instantiate(storyboard: .tutorial)
        }
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? TutorialViewController else { return self }
        
        vc.sceneType = .tutorial
        let useCase = TutorialUseCase()
        let viewModel = TutorialViewModel(useCase: useCase, navigator: self)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension TutorialCoordinator: TutorialNavigateProtocol {
    
    func toLogin() {
    LoginCoordinator(parentCoord: self)
        .prepare(routeLogin: .tutorial)
        .start()
    }
    
    func toHome() {
        MainCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    
    func moveToRegisterPremium() {
        let requestPremiumCoodinator = RequestPremiumCoodinator(parentCoord: self)
        requestPremiumCoodinator.delegate = self
        requestPremiumCoodinator.prepare().presentInNavigationController(orientationMask: .all)
    }
    
    var isDismissRegisterPremium: PublishSubject<Bool> {
        return self.isDismissRegisterPremiumOb
    }
}
extension TutorialCoordinator: RequestPremiumDelegate {
    func dismissRequestPremium() {
        self.isDismissRegisterPremiumOb.onNext(true)
    }
}
