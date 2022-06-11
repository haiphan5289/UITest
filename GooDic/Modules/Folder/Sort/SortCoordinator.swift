//
//  SortCoordinator.swift
//  GooDic
//
//  Created by haiphan on 09/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//
import UIKit

protocol SortDelegate {
    func dismissSort()
    func updateSort(sort: SortModel)
}

protocol SortNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func dismiss()
    func updateSort(sort: SortModel)
    func updateHeightViewAfterPaid()
    func moveToPrenium()
    func updateSizeWithRotation(size: CGSize)
}

class SortCoodinator: CoordinateProtocol {
    
    enum StatusRotation {
        case ipad, iphonePortrait, iphoneLandscape
        
        static func getStatus(size: CGSize) -> Self {
            switch DetectDevice.share.currentDevice {
            case .phone:
                if DetectDevice.share.detectLandscape(size: size) {
                    return .iphoneLandscape
                } else {
                    return .iphonePortrait
                }
                
            default: return .ipad
            }
        }
    }
    
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
        static let animationDuration: TimeInterval = 0.3
        static let heightViewPaid: CGFloat = 300
        static let sizeCellNormal: CGFloat = 50
        static let sizeCellPrenium: CGFloat = 78
        static let distanceToBottom: CGFloat = 30
        static let heightViewFree: CGFloat = (Constant.sizeCellNormal * 5) + Constant.sizeCellPrenium + Constant.distanceToBottom
        static let heightViewFreeDrafts: CGFloat = (Constant.sizeCellNormal * 4) + Constant.sizeCellPrenium + Constant.distanceToBottom
        static let heightViewPaidDrafts: CGFloat = (Constant.sizeCellNormal * 3) + Constant.sizeCellPrenium + Constant.distanceToBottom
    }
    
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    var bottomLayoutConstraint: NSLayoutConstraint!
    var delegate: SortDelegate?
    private var heightView: CGFloat = 0
    private var heightConstraint: NSLayoutConstraint!
    private var openfromScreen: SortVM.openfromScreen = .folderLocal
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = SortVC.instantiate(storyboard: .sort)
        }
    }
    
    @discardableResult
    func prepare(openfromScreen: SortVM.openfromScreen, sortModel: SortModel, folder: Folder?) -> SortCoodinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? SortVC else { return self }
        
//        vc.sceneType = .sort
        self.openfromScreen = openfromScreen
        let useCase = SortUseCase()
        let viewModel = SortVM(navigator: self, useCase: useCase, openfromScreen: openfromScreen, sortModel: sortModel, folder: folder)
        vc.bindViewModel(viewModel)
        
        return self
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
        
        let height: CGFloat = self.getHeightView(size: UIScreen.main.bounds.size)
        self.heightView = height
        self.heightConstraint = wrappedVC.view.heightAnchor.constraint(equalToConstant: height)
        
        NSLayoutConstraint.activate([
            wrappedVC.view.leftAnchor.constraint(equalTo: parentVC.view.leftAnchor),
            wrappedVC.view.rightAnchor.constraint(equalTo: parentVC.view.rightAnchor),
            self.bottomLayoutConstraint,
            self.heightConstraint
        ])
        
        self.heightConstraint?.isActive = true
        
        // start a presenting anim
        let userInfo = Notification.Name.encodeSuggestion(height: parentVC.view.bounds.height * 0.5, animationDuration: Constant.animationDuration)
        NotificationCenter.default.post(name: .willPresentSuggestion, object: nil, userInfo: userInfo)
        
        bottomLayoutConstraint!.constant = wrappedVC.view.bounds.height + AppManager.shared.getHeightSafeArea(type: .bottom)
        parentVC.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.bottomLayoutConstraint.constant = 0
            parentVC.view.layoutIfNeeded()
        }
        wrappedVC.tabBarController?.tabBar.isHidden = true
    }
    
    private func getHeightView(size: CGSize) -> CGFloat {
        switch StatusRotation.getStatus(size: size) {
        case .ipad, .iphonePortrait:
            if AppManager.shared.billingInfo.value.billingStatus == .free {
                switch self.openfromScreen {
                case .folderCloud, .folderLocal: return Constant.heightViewFree
                case .draftsLocal, .draftsCloud: return Constant.heightViewFreeDrafts
                }
            } else {
                switch self.openfromScreen {
                case .draftsLocal, .draftsCloud:
                    return Constant.heightViewPaidDrafts
                case .folderCloud, .folderLocal:
                    return Constant.heightViewPaid
                }
            }
        default:
            return size.height / 2
        }

    }
}

extension SortCoodinator: SortNavigateProtocol {
    
    func updateSizeWithRotation(size: CGSize) {
        guard let parentVC = self.parentCoord?.viewController else { return }
        let height: CGFloat = self.getHeightView(size: size)
        self.heightView = height
        self.heightConstraint?.constant = height
        UIView.animate(withDuration: 0.3) {
            parentVC.view.layoutIfNeeded()
        }
    }
    
    func moveToPrenium() {
        RequestPremiumCoodinator(parentCoord: self)
            .prepare()
            .presentInNavigationController(orientationMask: .all)
    }
    
    func updateHeightViewAfterPaid() {
        guard let parentVC = parentCoord?.viewController else { return }
        switch self.openfromScreen {
        case .draftsLocal, .draftsCloud:
            self.heightConstraint?.constant = Constant.heightViewPaidDrafts
            self.heightView = Constant.heightViewPaidDrafts
        case .folderCloud, .folderLocal:
            self.heightConstraint?.constant = Constant.heightViewPaid
            self.heightView = Constant.heightViewPaid
        }
        UIView.animate(withDuration: 0.3) {
            parentVC.view.layoutIfNeeded()
        }
    }
    
    func updateSort(sort: SortModel) {
        self.delegate?.updateSort(sort: sort)
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
            self.delegate?.dismissSort()
        })
    }
}
