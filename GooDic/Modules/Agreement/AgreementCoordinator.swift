//
//  AgreementCoordinator.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol AgreementNavigateProtocol {
    func quit()
    func toNotifyNewAgreementAlert()
    func toDisagreeAlert() -> Observable<Bool>
    func toTutorial()
    func toMainView()
    func toExternalWebView(url: URL)
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene)
    func moveCustomDialog()
}

class AgreementCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = AgreementViewController.instantiate(storyboard: .agreement)
        }
    }
    
    @discardableResult
    func prepare(url: URL, dateVersion: Date, sceneType: GATracking.Scene) -> AgreementCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? AgreementViewController else { return self }
        
        vc.sceneType = sceneType
        let data = AgreementData(date: dateVersion, url: url)
        let useCase = AgreementUseCase()
        let viewModel = AgreementViewModel(data: data, useCase: useCase, navigator: self)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func startInNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.navigationBar.tintColor = Asset.textPrimary.color
        
        UIWindow.key?.rootViewController = nc
    }
}

extension AgreementCoordinator: AgreementNavigateProtocol {
    func quit() {
        exit(0) // quit
    }
    
    func toNotifyNewAgreementAlert() {
        let alert = UIAlertController(title: L10n.Agreement.New.title,
                                      message: L10n.Agreement.New.message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Agreement.New.ok, style: .cancel, handler: nil))

        viewController.present(alert, animated: true, completion: nil)
    }
    
    func moveCustomDialog() {
        CustomDialogCoordinator.init(parentCoord: self)
            .prepare()
            .show()
    }
    
    
    func toDisagreeAlert() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Agreement.Confirm.close, style: .cancel),
            .action(title: L10n.Agreement.Confirm.return, style: .default)
        ]

        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == L10n.Agreement.Confirm.close {
                action.setValue(Asset.textSecondary.color, forKey: "titleTextColor")
            }
            else {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            }
        }

        let displayName = Bundle.main.displayName ?? "draft"

        return UIAlertController
            .present(in: viewController,
                     title: nil,
                     message: L10n.Agreement.Confirm.message(displayName),
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 0 })
    }
    
    func toTutorial() {
        TutorialCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    
    func toMainView() {
        MainCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    
    func toExternalWebView(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene) {
        WebCoordinator(parentCoord: self)
            .prepare(title: title, url: url, sceneType: sceneType, cachePolicy: cachePolicy)
            .push()
    }
}
