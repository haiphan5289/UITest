//
//  DrawPresentCoordinator.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol BackUpSettingDelegate {
    func dismissBackUp()
    func actionShareBackUp()
    func callBackSetting(settingFont: SettingFont)
}

protocol BackUpSettingCoordinatorProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func dismissDelegate()
    func actionShare()
    func moveToFont()
    func moveToPrenium()
    var updateSetting: PublishSubject<SettingFont> { get }
}

class BackUpSettingCoordinator: CoordinateProtocol {
    
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
        static let animationDuration: TimeInterval = 0.3
        static let heightViewiCloud: CGFloat = 200
    }
    
    var parentCoord: CoordinateProtocol?
    var settingCoord: SettingCoordinator?
    weak var viewController: UIViewController!
    private var bottomLayoutConstraint: NSLayoutConstraint!
    private var heightView: CGFloat = 0
    private var updateSettingEvent: PublishSubject<SettingFont> = PublishSubject.init()
    var delegate: BackUpSettingDelegate?
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = BackUpSettingVC.instantiate(storyboard: .setting)
        }
    }
    
    @discardableResult
    func prepare(drafts: [Document]) -> BackUpSettingCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? BackUpSettingVC else { return self }
        
        let useCase = BackUpSettingUseCase()
        let viewModel = BackUpSettingVM(navigator: self, useCase: useCase, drafts: drafts)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    func presentWithNavigationController() {
        let nc = BaseNavigationController(rootViewController: viewController)
        nc.modalPresentationStyle = .fullScreen
        
        parentCoord?.viewController.present(nc, animated: true, completion: nil)
    }
    
    func presentInNavigationController() {
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
            wrappedVC.view.heightAnchor.constraint(equalToConstant: Constant.heightViewiCloud + AppManager.shared.getHeightSafeArea(type: .bottom))
        ])
        self.heightView = Constant.heightViewiCloud + AppManager.shared.getHeightSafeArea(type: .bottom)
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
        })
    }
    
    
}

extension BackUpSettingCoordinator: BackUpSettingCoordinatorProtocol {
    var updateSetting: PublishSubject<SettingFont> {
        return self.updateSettingEvent
    }
    
    func moveToPrenium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
    }
    
    func moveToFont() {
        self.settingCoord = SettingCoordinator(parentCoord: self)
        self.settingCoord?.delegate = self
        self.settingCoord!
            .prepare(onCloud: true)
            .push()
    }
    
    func actionShare() {
        self.delegate?.actionShareBackUp()
    }
    
    func dismissDelegate() {
        self.delegate?.dismissBackUp()
    }
}
extension BackUpSettingCoordinator: SettingDelegateCallBack {
    func callBackSetting(settingFont: SettingFont) {
        self.delegate?.callBackSetting(settingFont: settingFont)
        self.updateSettingEvent.onNext(settingFont)
    }
    
    func dismissSettingFontView() {
        
    }
}
