//
//  AppCoordinator.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import RxSwift

protocol AppNavigateProtocol: CoordinateProtocol, ErrorMessageProtocol {
    func quit()
    func toAgreementView(url: URL, dateVersion: Date)
    func toReagreementView(url: URL, dateVersion: Date)
    func toTutorial()
    func toMain()
    func toDynamicView(description: String, entryAction: EntryAction)
    func toNetworkErrorAlert() -> Observable<Bool>
    func toLogin()
    func toForceLogout()
    func toListDeviceWithCaseOverLimit()
    func toForceUpdate(object: FileStoreForceUpdate?) -> Observable<Bool>
    func toAppstore()
}

class AppCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    var mainCoord: MainCoordinator?
    
    weak var viewController: UIViewController!
    
    private var window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = AppViewController.instantiate(storyboard: .app)
        }
    }
    
    @discardableResult
    func prepare() -> AppCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? AppViewController else { return self }
        let useCase = AppUseCase()
        let viewModel = AppViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        makeCosmetic()
        
        return self
    }
    
    private func makeCosmetic() {
        let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 18)]
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = atts
            appearance.backgroundColor = Asset.background.color
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            UINavigationBar.appearance().titleTextAttributes = atts
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().barTintColor = Asset.background.color
        }
        
        UITabBar.appearance().barTintColor = Asset.background.color
        
        UIToolbar.appearance().isTranslucent = false
        UIToolbar.appearance().barTintColor = Asset.background.color
        
        /// while pushing view controller, you can see a background with black if a navigation bar's style is transparent.
        /// You should set the window's background color to white to prevent it.
        window.backgroundColor = Asset.background.color
    }
    
    private func makeUpText(_ message: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle

        var messageText: NSMutableAttributedString
        if #available(iOS 13.0, *) {
            messageText = NSMutableAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: UIColor.label,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        } else {
            messageText = NSMutableAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        }
        return messageText
    }
    
    func start() {
        self.window.rootViewController = viewController
        self.window.makeKeyAndVisible()
    }
}

extension AppCoordinator: AppNavigateProtocol {
    func quit() {
        exit(0) // quit
    }

    func toAgreementView(url: URL, dateVersion: Date) {
        toAgreementView(url: url, dateVersion: dateVersion, sceneType: .agreement)
    }
    
    func toReagreementView(url: URL, dateVersion: Date) {
        toAgreementView(url: url, dateVersion: dateVersion, sceneType: .reAgreement)
    }

    func toAgreementView(url: URL, dateVersion: Date, sceneType: GATracking.Scene) {
        AgreementCoordinator(parentCoord: self)
            .prepare(url: url, dateVersion: dateVersion, sceneType: sceneType)
            .startInNavigationController()
    }
    
    func toTutorial() {
        TutorialCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    func toLogin() {
        LoginCoordinator(parentCoord: self)
            .prepare(routeLogin: .app)
            .start()
    }

    func toMain() {
        mainCoord = MainCoordinator(parentCoord: self)
        mainCoord?.prepare()
            .start()
    }
    
    func toListDeviceWithCaseOverLimit() {
        RegisterDeviceCoordinator(parentCoord: self)
            .prepare(typeRegister: .detectStatusUserWhenStartApp)
            .startInNavigationController()
    }

    func toDynamicView(description: String, entryAction: EntryAction) {
        guard let appURI = AppURI(rawValue: description) else { return }

        if mainCoord == nil {
            toMain()
        }

        mainCoord!.toDynamicView(appURI: appURI, entryAction: entryAction)
    }

    func toNetworkErrorAlert() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        return UIAlertController
            .present(in: viewController,
                     title: L10n.Alert.Network.title,
                     message: L10n.Alert.Network.message,
                     style: .alert,
                     actions: actions)
            .map({ $0 == 0 })
    }
    
    func toForceLogout() {
        RegistrationLogoutCoordinator(parentCoord: self)
            .prepare()
            .start()
    }
    
    func toForceUpdate(object: FileStoreForceUpdate?) -> Observable<Bool> {
        toForceUpdateAlert(object: object)
    }
    
    func toForceUpdateAlert(object: FileStoreForceUpdate?) -> Observable<Bool> {
        guard let title = object?.messageTitle, let msg = object?.messageText, let actionTitle = object?.messageButtonText else {
            return Observable.just(false) 
        }
        let actions: [AlertAction] = [
            .action(title: actionTitle, style: .default)
        ]
        
        let messageText = makeUpText(msg)
        return UIAlertController
            .presentAutoReShowAlert(in: viewController,
                                    title: title,
                                    message: messageText,
                                    style: .alert,
                                    actions: actions,
                                    cosmeticBlock: nil)
            .map({ $0 == 0 })
    }
    
    func toAppstore() {
        if let url = URL(string: GlobalConstant.appItunesString),
                UIApplication.shared.canOpenURL(url){
            UIApplication.shared.open(url, options: [:]) { (opened) in
                
            }
        }
    }
    
}
