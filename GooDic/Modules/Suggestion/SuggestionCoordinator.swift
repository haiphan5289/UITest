//
//  SuggestionCoordinator.swift
//  GooDic
//
//  Created by ttvu on 5/26/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol SuggestionNavigateProtocol {
    func dismiss()
    func toDetail(url: URL)
    func toFeedback()
}

class SuggestionCoordinator: CoordinateProtocol {
    struct Constant {
        static let radius: CGFloat = 16
        static let shadowColor: UIColor = Asset.naviBarShadow.color
        static let shadowOffset: CGSize = CGSize(width: 2, height: -3)
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 1
        static let animationDuration: TimeInterval = 0.3
    }
    
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    private var bottomLayoutConstraint: NSLayoutConstraint!
    private var heightView: CGFloat = 0
    
    let delegate = PublishSubject<SuggestionDelegate>()
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = SuggestionViewController.instantiate(storyboard: .suggestion)
        }
    }
    
    @discardableResult
    func prepare(title: String, titleData: GDData, contentData: GDData, sceneType: GATracking.Scene = .unknown) -> SuggestionCoordinator {
        createViewControllerIfNeeded()
        guard let vc = viewController as? SuggestionViewController else { return self }
        
        vc.sceneType = sceneType
        vc.title = title
        let useCase = SuggestionUseCase()
        let viewModel = SuggestionViewModel(titleData: titleData,
                                            contentData: contentData,
                                            useCase: useCase,
                                            navigator: self,
                                            delegate: delegate)
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
        NSLayoutConstraint.activate([
            wrappedVC.view.leftAnchor.constraint(equalTo: parentVC.view.leftAnchor),
            wrappedVC.view.rightAnchor.constraint(equalTo: parentVC.view.rightAnchor),
            bottomLayoutConstraint,
            wrappedVC.view.heightAnchor.constraint(equalTo: parentVC.view.heightAnchor, multiplier: 0.5)
        ])
        
        // start a presenting anim
        let userInfo = Notification.Name.encodeSuggestion(height: parentVC.view.bounds.height * 0.5, animationDuration: Constant.animationDuration)
        NotificationCenter.default.post(name: .willPresentSuggestion, object: nil, userInfo: userInfo)
        
        bottomLayoutConstraint!.constant = wrappedVC.view.bounds.height
        parentVC.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.bottomLayoutConstraint.constant = 0
            parentVC.view.layoutIfNeeded()
        }
        self.heightView = wrappedVC.view.bounds.height
    }
}

extension SuggestionCoordinator: SuggestionNavigateProtocol {
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
    
    func toDetail(url: URL) {
        WebCoordinator(parentCoord: self)
            .prepareNaviWebView(title: L10n.Suggestion.Detail.title, url: url, sceneType: .searchResultslnDraft, openFrom: .suggestion)
            .presentInNavigationController(orientationMask: .all)
    }
    
    func toFeedback() {
        let url = URL(string: GlobalConstant.feedbackURL)!
        
        WebCoordinator(parentCoord: self)
            .prepareFeedbackVC(title: L10n.Suggestion.Feedback.title, url: url, sceneType: .feedback)
            .presentInNavigationController(orientationMask: .all)
    }
}

extension SuggestionCoordinator: SuggestionVCNavigationDelegate {
    func dismiss(vc: SuggestionViewController) {
        vc.dismiss(animated: true, completion: nil)
    }
}
