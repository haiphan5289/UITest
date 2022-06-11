//
//  ConfirmPremiumViewController.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/2/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ConfirmPremiumViewController: BaseViewController, ViewBindableProtocol {

    // MARK: - UI
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var btDismiss: UIBarButtonItem!
    @IBOutlet weak var termButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var productNamePrice: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var idraftLabel: UILabel!
    @IBOutlet weak var containerMainButtonView: UIView!
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: ConfirmPremiumViewModel!
    var isIPAInProccess = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        idraftLabel.setLineHeight(lineHeight: 8)
        headerLabel.setLineHeight(lineHeight: 8, shouldCenter: true)
        containerMainButtonView.layer.borderWidth = 0.5
        containerMainButtonView.layer.borderColor = Asset.cececeClear.color.cgColor
        let attributeString = NSMutableAttributedString(
            attributedString: self.attributeStringWith(text: L10n.Premium.note, paragraphSpacing: 6))
        attributeString.append(self.attributeStringWith(text: L10n.Premium.note2, paragraphSpacing: 0))
        noteLabel.attributedText = attributeString
        if let billingText = AppManager.shared.billingText {
            nextButton.setTitle(billingText.titleDisplay(isLogin: true, isConfirmScreen: true), for: .normal)
        }
        self.setupBarItem(traitCollection: self.traitCollection)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationTitle()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if #available(iOS 13.0, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: newCollection) {
            self.setupBarItem(traitCollection: newCollection)
        }
    }
    
    private func setupNavigationTitle() {
        setupNavigationTitle(type: .requestPremium)
    }
    
    private func setupBarItem(traitCollection: UITraitCollection?) {
        guard let traitCollection = traitCollection else { return  }
        traitCollection.userInterfaceStyle == .dark ? (btDismiss.tintColor = .white) : (btDismiss.tintColor = Asset._4C4C4C.color)
    }
    
    func bindViewModel() {
        let purchaseSucceed = NotificationCenter.default.rx
            .notification(.IAPHelperPurchaseNotification)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let beginPurchaseSucceed = NotificationCenter.default.rx
            .notification(.IAPHelperBeginPurchaseNotification)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let endPurchaseSucceed = NotificationCenter.default.rx
            .notification(.IAPHelperEndPurchaseNotification)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let input = ConfirmPremiumViewModel.Input(
            loadData: Driver.just(()),
            nextTrigger: nextButton.rx.tap.asDriver(),
            dismissTrigger: self.btDismiss.rx.tap.asDriver(),
            purcharseSucceed: purchaseSucceed,
            useInfo: AppManager.shared.userInfo.asDriver(),
            privacyTrigger: privacyButton.rx.tap.asDriver(),
            termTrigger: termButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.listProducts
            .drive()
            .disposed(by: self.disposeBag)
        
        output.buyProductTrigger
            .drive()
            .disposed(by: self.disposeBag)
        
        output.purcharseSucceed
            .drive()
            .disposed(by: self.disposeBag)
        
        output.dismissTrigger.drive().disposed(by: disposeBag)
        output.viewTermAction.drive().disposed(by: disposeBag)
        output.viewPrivacyAction.drive().disposed(by: disposeBag)
        output.userPaidAction.drive().disposed(by: disposeBag)
        output.result.drive().disposed(by: disposeBag)
        output.errorBillingHandler.drive().disposed(by: disposeBag)

        output.loading
            .drive(onNext: {[weak self] show in
                if show {
                    GooLoadingViewController.shared.show()
                } else if self?.isIPAInProccess == false {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)
        
        beginPurchaseSucceed
            .drive(onNext: {[weak self] _ in
                self?.isIPAInProccess = true
                GooLoadingViewController.shared.show()
            })
            .disposed(by: self.disposeBag)
        
        purchaseSucceed.drive(onNext: { [weak self] _ in
            self?.isIPAInProccess = false
        })
        .disposed(by: self.disposeBag)
        
        endPurchaseSucceed
            .drive(onNext: { [weak self] _ in
                self?.isIPAInProccess = false
                GooLoadingViewController.shared.hide()
            })
            .disposed(by: self.disposeBag)
        
        tracking()
    }
    
    private func tracking() {
        GATracking.scene(self.sceneType)
        nextButton.rx.tap
            .bind(onNext: {
                GATracking.tap(.tapRegisterForPremium)
            })
            .disposed(by: self.disposeBag)
    }
}
