//
//  MenuCoordinator.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//
import UIKit
import RxSwift

protocol MenuNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol, AppManagerProtocol {
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]?)
    func toShareView(url: URL, rect: CGRect?)
    func updateShareView(rect: CGRect?)
    func toTrash()
    func toLogoutConfirmation() -> Observable<Bool>
    func toDevicesScreen()
    func toLoginScreen()
    func toRequestPremium()
    func toAccountInfo()
    func toListDevice()
    func toShareStringView(content: String, rect: CGRect?)
    func toGooTwitter()
    func toSettingEnviromental()
}

class MenuCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    var activityViewController: UIActivityViewController?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        guard let vc = viewController as? MenuViewController else { return self }
        
        vc.sceneType = .menu
        let useCase = MenuUseCase()
        let viewModel = MenuViewModel(data: createMenuData(), useCase: useCase, navigator: self)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension MenuCoordinator: MenuNavigateProtocol {
    
    func toListDevice() {
        RegisterDeviceCoordinator(parentCoord: self)
            .prepare(typeRegister: .detecStatusUser)
            .push()
    }
    
    func toWebView(url: URL, cachePolicy: URLRequest.CachePolicy, title: String, sceneType: GATracking.Scene, internalLinkDatas: [LinkData]? = nil) {
        
        var handleLinkBlock: ((URL) -> Bool)? = nil
        if let internalLinkDatas = internalLinkDatas {
            handleLinkBlock = {[weak self] (url: URL) -> Bool in
                if let data = internalLinkDatas.first(where: { $0.ulr == url.absoluteString }) {
                    if url.absoluteString == GlobalConstant.billingRequestUri {
                        self?.viewController.navigationController?.popViewController(animated: false)
                        if AppManager.shared.billingInfo.value.billingStatus == .free {
                            self?.toRequestPremium()
                        } else {
                            self?.toAccountInfo()
                        }
                        return true
                    }
                    self?.toWebView(url: url, cachePolicy: data.cachePolicy, title: data.title, sceneType: data.sceneType)
                    return true
                }

                return false
            }
        }

        WebCoordinator(parentCoord: self)
            .prepare(title: title, url: url, sceneType: sceneType, cachePolicy: cachePolicy, handleLinkBlock: handleLinkBlock, allowOrientation: .all)
            .push()
    }
    
    func toShareView(url: URL, rect: CGRect?) {
        let displayName = Bundle.main.displayName ?? "draft"
        let shareContent = L10n.Menu.shareContent(displayName)
        let item = GooActivityTypeSource(content: shareContent,
                                         placeholderImage: Asset.iTunesArtwork.image)

        activityViewController = UIActivityViewController(activityItems: [item], applicationActivities: nil)

        updateShareView(rect: rect)

        viewController.present(activityViewController!, animated: true)
    }
    
    func toShareStringView(content: String, rect: CGRect?) {
        let item = GooActivityTypeSource(content: content,
                                         placeholderImage: Asset.iTunesArtwork.image)

        activityViewController = UIActivityViewController(activityItems: [item], applicationActivities: nil)

        updateShareView(rect: rect)

        viewController.present(activityViewController!, animated: true)
    }
    
    func updateShareView(rect: CGRect?) {
        // avoiding to crash on iPad
        if let popoverController = activityViewController?.popoverPresentationController {
            if let sourceRect = rect {
                popoverController.sourceRect = sourceRect
                popoverController.sourceView = viewController.view
            } else {
                popoverController.sourceRect = viewController.navigationController?.navigationBar.frame ?? .zero
                popoverController.sourceView = viewController.navigationController?.navigationBar
            }
            
            popoverController.permittedArrowDirections = .any
        }
    }
    
    func toTrash() {
        TrashCoordinator(parentCoord: self)
            .prepare()
            .push()
    }
    
    func toLogoutConfirmation() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Account.LogoutConfirmation.cancel, style: .default),
            .action(title: L10n.Account.LogoutConfirmation.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == L10n.Account.LogoutConfirmation.ok {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.cancel.color, forKey: "titleTextColor")
            }
        }
        
        return UIAlertController
            .present(in: viewController,
                     title: L10n.Account.LogoutConfirmation.title,
                     message: L10n.Account.LogoutConfirmation.message,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
    
    func toDevicesScreen() {
        RegisterDeviceCoordinator(parentCoord: self)
            .prepare(typeRegister: .menu)
            .push()
    }
    
    func toLoginScreen() {
        LoginCoordinator(parentCoord: self)
            .prepare(routeLogin: .menu)
            .push()
    }
    
    func toRequestPremium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
        
        let userStatus: GATracking.UserStatus = AppManager.shared.userInfo.value == nil
            ? .other
            : .regular
        GATracking.tap(.tapViewPremiumInMenu, params: [.userStatus(userStatus)])
    }
    
    func toAccountInfo() {
        AccountInfoCoodinator(parentCoord: self)
            .prepare()
            .push()
    }
    
    func toGooTwitter() {
        if let url = URL(string: GlobalConstant.gooTwitterUrl),
                UIApplication.shared.canOpenURL(url){
            UIApplication.shared.open(url, options: [:]) { (opened) in
            }
        }
    }
    func toSettingEnviromental() {
        SettingEnviromentalCoordinator(parentCoord: self)
            .prepare()
            .push()
    }
}
