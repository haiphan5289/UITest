//
//  SettingSearchCoordinator.swift
//  GooDic
//
//  Created by paxcreation on 5/20/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol SettingSearchDelegate {
    func callBackSetting(settingSearch: SettingSearch)
    func dismissSettingSearchView()
    func actionPremium()
}

protocol SettingSearchNavigateProtocol: ErrorMessageProtocol {
    func callBackSetting(settingSearch: SettingSearch)
    func dismissSettingSearchView()
    func actionPremium()
    func updateHeightViewAfterPaid()
}

class SettingSearchCoordinator: CoordinateProtocol {
    
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
        static let animationDuration: TimeInterval = 0.3
        static let heightForPaid: CGFloat = 200
        static let heightForIPhone: CGFloat = 250
    }
    
    var parentCoord: CoordinateProtocol?
    weak var viewController: UIViewController!
    var delegate: SettingSearchDelegate?
    private var bottomLayoutConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint?
    private var heightView: CGFloat = 0
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = SettingSearchViewController.instantiate(storyboard: .settingSearch)
        }
    }
    
    @discardableResult
    func prepare(sceneType: GATracking.Scene = .searchOptions) -> SettingSearchCoordinator {
        createViewControllerIfNeeded()
        
        guard let vc = viewController as? SettingSearchViewController else { return self }
        vc.sceneType = sceneType
        let useCase = SettingSearchUseCase()
        let viewModel = SettingSearchVM(navigator: self, useCase: useCase)
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
        
        let height: CGFloat
        if AppSettings.settingSearch?.billingStatus == .free {
            height = Constant.heightForIPhone
        } else {
            height = Constant.heightForPaid
        }
        self.heightView = height
        NSLayoutConstraint.activate([
            wrappedVC.view.leftAnchor.constraint(equalTo: parentVC.view.leftAnchor),
            wrappedVC.view.rightAnchor.constraint(equalTo: parentVC.view.rightAnchor),
            bottomLayoutConstraint,
            wrappedVC.view.heightAnchor.constraint(equalToConstant: height)
        ])
        heightConstraint = wrappedVC.view.heightAnchor.constraint(equalToConstant: height)
        heightConstraint?.isActive = true
        
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
extension SettingSearchCoordinator: SettingSearchNavigateProtocol {
    func updateHeightViewAfterPaid() {
        guard let parentVC = parentCoord?.viewController else { return }
        heightConstraint?.constant = Constant.heightForPaid
        UIView.animate(withDuration: 0.3) {
            parentVC.view.layoutIfNeeded()
        }
    }
    
    func callBackSetting(settingSearch: SettingSearch) {
        self.delegate?.callBackSetting(settingSearch: settingSearch)
    }
    
    func dismissSettingSearchView() {
        self.delegate?.dismissSettingSearchView()
    }
    
    func actionPremium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
    }
    

}
