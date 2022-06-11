//
//  SettingCoordinator.swift
//  GooDic
//
//  Created by paxcreation on 5/19/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol SettingDelegateCallBack: ErrorMessageProtocol {
    func callBackSetting(settingFont: SettingFont)
    func dismissSettingFontView()
    func actionShare()
}

protocol SettingNavigateProtocol: ErrorMessageProtocol {
    func callBackSetting(settingFont: SettingFont)
    func dismissDelegate()
    func actionShare()
    func popVC()
}

class SettingCoordinator: CoordinateProtocol {
    
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
        static let animationDuration: TimeInterval = 0.3
        static let heightViewiCloud: CGFloat = 300
        static let heightViewLocal: CGFloat = 250
    }
    
    var parentCoord: CoordinateProtocol?
    var delegate: SettingDelegateCallBack?
    weak var viewController: UIViewController!
    private var bottomLayoutConstraint: NSLayoutConstraint!
    private var heightView: CGFloat = 0
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = SettingViewController.instantiate(storyboard: .setting)
        }
    }
    
    @discardableResult
    func prepare(sceneType: GATracking.Scene = .settingsAndSharing, onCloud: Bool) -> SettingCoordinator {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? SettingViewController else { return self }
        vc.sceneType = sceneType
        let useCase = SettingUseCase()
        let viewModel = SettingViewModel(navigator: self, useCase: useCase, onCloud: onCloud)
        vc.bindViewModel(viewModel)
        
        return self
    }
    func presentWithNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.modalPresentationStyle = .fullScreen
        
        parentCoord?.viewController.present(nc, animated: true, completion: nil)
    }
    
    func presentInNavigationController(onCloud: Bool) {
        guard let parentVC = parentCoord?.viewController else { return }
        
        let nc = BaseNavigationController(rootViewController: viewController)
        let wrappedVC = ContainerViewController(root: nc)
        
        // cosmetics
        wrappedVC.view.layer.shadowColor = Constant.shadowColor.cgColor
        wrappedVC.view.layer.shadowOffset = Constant.shadowOffset
        wrappedVC.view.layer.shadowOpacity = Constant.shadowOpacity
        wrappedVC.view.layer.shadowRadius = Constant.shadowRadius
        
        nc.view.subviews.forEach({ (view) in
            view.layer.cornerRadius = Constant.radius
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            view.layer.masksToBounds = true
        })
        
        // add to view
        parentVC.addChild(wrappedVC)
        parentVC.view.addSubview(wrappedVC.view)
        wrappedVC.didMove(toParent: parentVC)

        // add constraints
        bottomLayoutConstraint = wrappedVC.view.bottomAnchor.constraint(equalTo: parentVC.view.bottomAnchor)
        wrappedVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrappedVC.view.leftAnchor.constraint(equalTo: parentVC.view.leftAnchor),
            wrappedVC.view.rightAnchor.constraint(equalTo: parentVC.view.rightAnchor),
            bottomLayoutConstraint,
            wrappedVC.view.heightAnchor.constraint(equalToConstant: (onCloud) ? Constant.heightViewiCloud : Constant.heightViewLocal)
        ])
        self.heightView = (onCloud) ? Constant.heightViewiCloud : Constant.heightViewLocal
        // start a presenting anim
        let userInfo = Notification.Name.encodeSuggestion(height: parentVC.view.bounds.height * 0.5, animationDuration: Constant.animationDuration)
        NotificationCenter.default.post(name: .willPresentSuggestion, object: nil, userInfo: userInfo)
        
        bottomLayoutConstraint!.constant = wrappedVC.view.bounds.height
        parentVC.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.bottomLayoutConstraint.constant = 0
            parentVC.view.layoutIfNeeded()
        }
    }
    
    func dismiss() {
        guard let parentVC = parentCoord?.viewController else { return }
        
        let userInfo = Notification.Name.encodeSuggestion(height: 0, animationDuration: Constant.animationDuration)
        NotificationCenter.default.post(name: .willDismissSuggestion, object: nil, userInfo: userInfo)
        
        parentVC.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomLayoutConstraint.constant = self.heightView
            parentVC.view.layoutIfNeeded()
        }, completion: { finished in
//            self.wrappedVC.view.removeFromSuperview()
        })
    }
}

extension SettingCoordinator: SettingNavigateProtocol {
    
    func popVC() {
        self.pop()
    }
    
    func actionShare() {
        self.delegate?.actionShare()
    }
    
    func dismissDelegate() {
        self.delegate?.dismissSettingFontView()
    }
    
    func callBackSetting(settingFont: SettingFont) {
        self.delegate?.callBackSetting(settingFont: settingFont)
    }
}

