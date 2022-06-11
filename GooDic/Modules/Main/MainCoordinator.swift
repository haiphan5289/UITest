//
//  MainCoordinator.swift
//  GooDic
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import UIKit
import FirebaseInAppMessaging

enum TabType: Int {
    case home = 0
    case folder = 1
    case dictionary = 2
    case menu = 3
}

enum EntryAction: Int {
    case inAppMsg = 0
    case notification = 1
    case topBanner = 2
    case schemeUriNormal = 3
}

protocol MainNavigateProtocol {
    func toDynamicView(appURI: AppURI, entryAction: EntryAction)
    func toFolder(folder: Folder)
}

class MainCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    var folderCoord: FolderBrowserCoordinator?
    var mainCoord: HomeCoordinator?
    var menuCoord: MenuCoordinator?
    var creationCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    var tabBarController: MainViewController {
        viewController as! MainViewController
    }
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = MainViewController.instantiate(storyboard: .main)
        }
        
        if #available(iOS 13.0, *) {
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appCoordinator.mainCoord = self
        } else {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.appCoordinator?.mainCoord = self
            }
        }
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        createViewControllerIfNeeded()
        
        let useCase = MainUseCase()
        let viewModel = MainViewModel(useCase: useCase, coordinator: self)
        tabBarController.bindViewModel(viewModel)

        tabBarController.viewControllers?.forEach({ (vc) in
            if let nc = vc as? UINavigationController {
                nc.navigationBar.tintColor = Asset.textPrimary.color

                if let homeVC = nc.viewControllers.first as? HomeViewController {
                    let coord = HomeCoordinator(parentCoord: self)
                    coord.viewController = homeVC
                    coord.prepare()
                    mainCoord = coord
                }
                else if let folderVC = nc.viewControllers.first as? FolderBrowserViewController {
                    let coord = FolderBrowserCoordinator(parentCoord: self)
                    coord.viewController = folderVC
                    coord.prepare()
                    folderCoord = coord
                }
                else if let dictionaryVC = nc.viewControllers.first as? DictionaryViewController {
                    let coord = DictionaryCoordinator(parentCoord: self)
                    coord.viewController = dictionaryVC
                    coord.prepare()
                }
                else if let menuVC = nc.viewControllers.first as? MenuViewController {
                    let coord = MenuCoordinator(parentCoord: self)
                    coord.viewController = menuVC
                    coord.prepare()
                    menuCoord = coord
                }
            }
        })

        makeCosmetic()
        
        return self
    }
    
    private func makeCosmetic() {
        tabBarController.tabBar.tintColor = Asset.textHighlight.color
        
        UIWindow.key?.tintColor = Asset.textPrimary.color
    }
}

extension MainCoordinator: MainNavigateProtocol {
    func toDynamicView(appURI: AppURI, entryAction: EntryAction) {
        switch appURI {
        case .home:
            if tabBarController.presentedViewController == nil {
                tabBarController.selectedIndex = TabType.home.rawValue
            }
        case .folder:
            if tabBarController.presentedViewController == nil {
                tabBarController.selectedIndex = TabType.folder.rawValue
            }
        case .search:
            if tabBarController.presentedViewController == nil {
                tabBarController.selectedIndex = TabType.dictionary.rawValue
            }
        case .menu:
            if tabBarController.presentedViewController == nil {
                tabBarController.selectedIndex = TabType.menu.rawValue
            }
        case .info:
            if let url = URL(string: GlobalConstant.notificationURL) {
                toWebView(url: url,
                          cachePolicy: .reloadIgnoringCacheData,
                          title: L10n.Menu.Cell.notification,
                          sceneType: .info,
                          entryAction: entryAction
                )
            }
            
        case .help:
            if let url = URL(string: GlobalConstant.helpURL) {
                toWebView(url: url,
                          cachePolicy: .reloadIgnoringCacheData,
                          title: L10n.Menu.Cell.help,
                          sceneType: .help,
                          entryAction: entryAction
                )
            }
            
        case .terms:
            if let url = URL(string: GlobalConstant.termURL) {
                toWebView(url: url,
                          cachePolicy: .reloadIgnoringCacheData,
                          title: L10n.Menu.Cell.terms,
                          sceneType: .terms,
                          entryAction: entryAction
                )
            }
            
        case .appPolicy:
            if let url = URL(string: GlobalConstant.appPolicyURL) {
                toWebView(url: url,
                          cachePolicy: .reloadIgnoringCacheData,
                          title: L10n.Menu.Cell.appPrivacyPolicy,
                          sceneType: .appPolicy,
                          entryAction: entryAction
                )
            }
            
        case .privacyPolicy:
            if let url = URL(string: GlobalConstant.privacyPolicyURL) {
                toWebView(url: url,
                          title: L10n.Menu.Cell.privacyPolicy,
                          sceneType: .privacyPolicy,
                          entryAction: entryAction
                )
            }
            
        case .personalDataPolicy:
            if let url = URL(string: GlobalConstant.personalDataPolicyURL) {
                toWebView(url: url,
                          title: L10n.Menu.Cell.personalInformation,
                          sceneType: .personalDataPolicy,
                          entryAction: entryAction
                )
            }
            
        case .openLicense:
            if let url = URL(string: GlobalConstant.openLicenseURL) {
                toWebView(url: url,
                          title: L10n.Menu.Cell.openLicense,
                          sceneType: .openLicense,
                          entryAction: entryAction
                )
            }
        case .registerDevice:
            self.toRegisterDevice()
        case .homeCloud:
            toHomeCloud()
        case .billingRequest:
            toRegisterPremium()
            break
        case .webURL(let url):
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func toFolder(folder: Folder) {
        tabBarController.selectedIndex = TabType.folder.rawValue
        switch folder.id {
        case .local(let id):
            if id.isEmpty {
                folderCoord?.toDraftList(in: nil)
            } else {
                folderCoord?.toDraftList(in: folder)
            }
            
        case .cloud(let id):
            if id.isEmpty {
                let cloudFolder = Folder(name: L10n.Folder.uncategorized, id: .cloud(""), manualIndex: nil, hasSortManual: false)
                folderCoord?.toDraftList(in: cloudFolder)
            } else {
                folderCoord?.toDraftList(in: folder)
            }
            
        default:
            break
        }
    }
    
    func toRegisterDevice() {
        guard let menuCoor = self.menuCoord, AppManager.shared.userInfo.value != nil else { return }
        self.tabBarController.selectedIndex = TabType.menu.rawValue
        RegisterDeviceCoordinator(parentCoord: menuCoor)
            .prepare(typeRegister: .menu)
            .push()
    }
    
    func toRegisterPremium() {
        guard let menuCoor = self.menuCoord else { return }
        self.tabBarController.selectedIndex = TabType.menu.rawValue
        if AppManager.shared.billingInfo.value.billingStatus == .free {
            RequestPremiumCoodinator(parentCoord: menuCoor)
                .prepare()
                .presentInNavigationController(orientationMask: .all)
            return
        }
        AccountInfoCoodinator(parentCoord: menuCoor)
            .prepare()
            .push()
    }
    
    func toHomeCloud() {
        tabBarController.selectedIndex = TabType.home.rawValue
        mainCoord?.toCloudTab()
    }
    
    private func toWebView(
        url: URL,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        title: String,
        sceneType: GATracking.Scene,
        entryAction: EntryAction
    ) {
        let openWebViewOnMenuBlock: () -> Void = { [weak self] in
            guard let self = self else { return }
            if entryAction != .topBanner {
                self.tabBarController.selectedIndex = TabType.menu.rawValue
            }
            
            guard let nv = self.tabBarController.selectedViewController as? UINavigationController, let vc = nv.topViewController, let menuCoord = self.menuCoord, let mainCoord = self.mainCoord else { return }

            let coord: WebCoordinator
            var animatedPush = true
            if entryAction != .topBanner {
                coord = WebCoordinator(parentCoord: menuCoord)
            } else {
                coord = WebCoordinator(parentCoord: mainCoord)
                animatedPush = false
            }
            
            if vc is MenuViewController || (vc is HomeViewController && entryAction == .topBanner) {
                coord.prepare(title: title, url: url, sceneType: sceneType)
                    .push(animated: animatedPush)
            } else if let topVC = vc as? WebViewController, title != topVC.title {
                coord.prepare(title: title, url: url, sceneType: sceneType)
                    .replace()
            }
        }
        
        guard let nv = viewController.presentedViewController as? UINavigationController,
              let vc = nv.topViewController else {
                  self.creationCoord = nil
                  if let presentedVC = viewController.presentedViewController {
                      presentedVC.dismiss(animated: true) {
                          openWebViewOnMenuBlock()
                      }
                  } else {
                      openWebViewOnMenuBlock()
                  }
                  return
              }
        
        if let topVC = vc as? CreationViewController,
            let coordinator = topVC.viewModel.navigator as? CoordinateProtocol {
            creationCoord = coordinator
            if topVC.presentedViewController != nil {
                topVC.dismiss(animated: true) {
                    WebCoordinator(parentCoord: coordinator)
                        .prepare(title: title, url: url, sceneType: sceneType)
                        .push()
                }
            } else {
                WebCoordinator(parentCoord: coordinator)
                    .prepare(title: title, url: url, sceneType: sceneType)
                    .push()
            }

        } else if let topVc = vc as? WebViewController, title != topVc.title,
                  let coordinator = creationCoord {
            WebCoordinator(parentCoord: coordinator)
                    .prepare(title: title, url: url, sceneType: sceneType)
                    .replace()
        }
    }
}
