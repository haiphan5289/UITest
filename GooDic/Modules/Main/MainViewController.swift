//
//  MainViewController.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseInAppMessaging
import CoreData

class MainViewController: UITabBarController, ViewBindableProtocol {
    
    // MARK: - UI
    var trashAnchor: UIView?
    lazy var tutorialTrashPopup: UIImageView = {
        let tutorial = UIImageView(image: Asset.imgTutoTrash.image)
        tutorial.addTapGesture { [weak self] (gesture) in
            self?.interactWithTrashTutorial.onNext(())
        }
        
        return tutorial
    }()
    var trashAnchorConstraintRight: NSLayoutConstraint?
    
    // MARK: - Rx + Data
    var viewModel: MainViewModel!
    let disposeBag = DisposeBag()
    var interactWithTrashTutorial = PublishSubject<Void>()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        tracking()
    }
    
    // MARK: - Funcs
    func setupUI() {
        if #available(iOS 15.0, *) {
            let appearance: UITabBarAppearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Asset.white111111.color
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
        self.delegate = self
    }
    
    func bindUI() {
        
    }
    
    private func tracking() {
        // track display mode
        GATracking.check(.displayMode, params: [.displayMode(traitCollection.userInterfaceStyle)])
    }
    
    func bindViewModel() {
        let hideToolBarTrigger = Observable.merge(
            NotificationCenter.default.rx.notification(.showTabBar).map({ _ in false }),
            NotificationCenter.default.rx.notification(.hideTabBar).map({ _ in true }))
            .asDriverOnErrorJustComplete()
            .do(onNext: { [weak self] hide in
                guard let self = self else { return }
                self.tabBar.alpha = hide ? 0 : 1
            })
        
        let clickButtonTrigger = InAppMessaging.inAppMessaging().rx
            .messageClicked
            .compactMap({ $0.actionURL?.absoluteString })
            .asDriverOnErrorJustComplete()
        
        let input = MainViewModel.Input(
            loadTrigger: Driver.just(()),
            clickInAppMessageButtonTrigger: clickButtonTrigger,
            viewDidAppearTrigger: self.rx.viewDidAppear.asDriver().mapToVoid(),
            viewDidLayoutSubviewsTrigger: self.rx.viewDidLayoutSubviews.asDriver().mapToVoid(),
            hideToolBarTrigger: hideToolBarTrigger,
            touchTrashTooltipTrigger: interactWithTrashTutorial.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.characterNumberOfDrafts
            .drive(onNext: GATracking.send(characterNumberOfDrafts:))
            .disposed(by: self.disposeBag)
        
        output.clickedButton
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showTrashTooltip
            .drive(onNext: { [weak self] show in
                guard
                    let self = self,
                    let buttonView = self.viewControllers?[TabType.menu.rawValue].tabBarItem.iconView
                else { return }
                
                if show {
                    let frameInView = buttonView.convert(buttonView.bounds, to: self.view)
                    
                    if self.trashAnchor == nil {
                        self.trashAnchor = UIView(frame: CGRect(origin: frameInView.topLeft, size: .zero))
                        self.view.addSubview(self.trashAnchor!)
                        self.trashAnchor?.translatesAutoresizingMaskIntoConstraints = false
                        self.trashAnchor?.backgroundColor = UIColor.red
                        let right = self.view.bounds.width - frameInView.minX - self.view.safeAreaInsets.right
                        let bottom = self.view.bounds.height - self.trashAnchor!.frame.minY - self.view.safeAreaInsets.bottom
                        
                        self.trashAnchorConstraintRight = self.view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: self.trashAnchor!.rightAnchor, constant: right)
                        self.trashAnchorConstraintRight?.isActive = true
                        
                        NSLayoutConstraint.activate([
                            self.trashAnchor!.widthAnchor.constraint(equalToConstant: 0),
                            self.trashAnchor!.heightAnchor.constraint(equalToConstant: 0),
                            self.trashAnchor!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -bottom)
                        ])
                    }
                    
                    var config = UIView.AnimConfig()
                    config.popupAnchorPoint = UIView.AnchorPoint.bottomRight
                    config.targetAnchorPoint = UIView.AnchorPoint.topLeft
                    
                    self.view.show(popup: self.tutorialTrashPopup, targetRect: frameInView, config: config, controlView: self.trashAnchor)
                } else {
                    self.view.dismiss(popup: self.tutorialTrashPopup)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.autoHideTooltips
            .drive()
            .disposed(by: self.disposeBag)
        
        output.checkedNewUser
            .drive(onNext: { _ in
                AppManager.shared.checkedNewUser.onNext(true)
            })
            .disposed(by: self.disposeBag)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return selectedViewController?.supportedInterfaceOrientations ?? .all
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.tabBar.backgroundImage = Asset.tabBarBg.image
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let menuVC = tabBarController.viewControllers?[TabType.menu.rawValue], menuVC == viewController {
            if let vc = menuVC as? UINavigationController {
                vc.popToRootViewController(animated: false)
            }
            self.interactWithTrashTutorial.onNext(())
        }
    }
}

// MARK: - Orientaion
extension MainViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { (context) in
            guard
                let buttonView = self.viewControllers?[TabType.menu.rawValue].tabBarItem.iconView
            else { return }
            
            if self.trashAnchorConstraintRight != nil {
                let frameInView = buttonView.convert(buttonView.bounds, to: self.view)
                let right = self.view.bounds.width - frameInView.minX - self.view.safeAreaInsets.right
                self.trashAnchorConstraintRight!.constant = right
                
                self.view.layoutIfNeeded()
            }
        }
    }
}
