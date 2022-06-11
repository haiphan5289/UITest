//
//  RequestPremiumViewController.swift
//  GooDic
//
//  Created by Hao Nguyen on 5/24/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit

class RequestPremiumViewController: BaseViewController, ViewBindableProtocol {
    
    // MARK: - UI
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var btDismiss: UIBarButtonItem!
    @IBOutlet weak var termButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var bottomButtonSpacing: NSLayoutConstraint!
    @IBOutlet weak var containerWebview: UIView!
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var heightNextButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var heightPlaceholderViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightGreaterThanPlaceholderViewConstraint: NSLayoutConstraint!
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: RequestPremiumViewModel!
    var isIPAInProccess = false
    
    lazy var progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.progressTintColor = Asset.highlight.color
        return view
    }()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if let billingText = AppManager.shared.billingText {
            self.handleDisplayNextButton(billingText: billingText)
        }
        setupUI()
        loadRequest()
    }
    
    private func handleDisplayNextButton(billingText: FileStoreBillingText) {
        let isLogin = AppManager.shared.userInfo.value != nil
        let topTitle = billingText.titleDisplay(isLogin: isLogin)
        let bottomTitle = billingText.titleBottomDisplay(isLogin: isLogin)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        let attrTitle = [
            NSAttributedString.Key.foregroundColor: Asset.textRegister.color,
            NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 16),
            NSAttributedString.Key.paragraphStyle:paragraphStyle
        ]
        let attrSubTitle = [
            NSAttributedString.Key.foregroundColor: Asset.textRegister.color,
            NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 12),
            NSAttributedString.Key.paragraphStyle:paragraphStyle
        ]
        
        let attTitleNormal = [
            NSAttributedString.Key.foregroundColor: Asset.textRegister.color,
            NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 15),
            NSAttributedString.Key.paragraphStyle:paragraphStyle
        ]

        nextButton.titleLabel?.numberOfLines = 0
        nextButton.titleLabel?.lineBreakMode = .byWordWrapping
        
        if let topTitle = topTitle, let bottomTitle = bottomTitle, topTitle != "" && bottomTitle != "" {
            let attr = self.attributedTexts(textFirst: topTitle, attribsFirst: attrTitle, textLast: bottomTitle, attribsLast: attrSubTitle)
            nextButton.setAttributedTitle(attr, for: .normal)
            self.updateHeightNextButton(isUpdate: true)
            self.updateAspectRatioPlaceholderView(isUpdate: true)
        } else {
            if let topTitle = topTitle {
                let attr = NSMutableAttributedString(string: topTitle, attributes: attTitleNormal)
                nextButton.setAttributedTitle(attr, for: .normal)
                self.updateHeightNextButton(isUpdate: false)
                self.updateAspectRatioPlaceholderView(isUpdate: false)
            }
        }
    }
    
    private func updateAspectRatioPlaceholderView(isUpdate: Bool) {
        if isUpdate {
            self.heightPlaceholderViewConstraint.constant = self.view.bounds.size.height * 2.1/9.0
            self.heightGreaterThanPlaceholderViewConstraint.constant = 175

        } else {
            self.heightPlaceholderViewConstraint.constant = self.view.bounds.size.height * 2.0/9.0
            self.heightGreaterThanPlaceholderViewConstraint.constant = 165
        }
    }
    
    private func attributedTexts(textFirst: String?, attribsFirst: [NSAttributedString.Key : Any]?, textLast: String?, attribsLast: [NSAttributedString.Key : Any]?) -> NSMutableAttributedString? {
        let combinationAttributedString =  NSMutableAttributedString()
        if let text = textFirst, let attribs = attribsFirst {
            let attributedString = NSMutableAttributedString(string: text, attributes: attribs)
            combinationAttributedString.append(attributedString)
        }
        
        if let text = textLast, let attribs = attribsLast {
            let attributedString = NSMutableAttributedString(string: text, attributes: attribs)
            combinationAttributedString.append(NSAttributedString(string: "\n"))
            combinationAttributedString.append(attributedString)
        }
        return combinationAttributedString
    }
    
    private func updateHeightNextButton(isUpdate: Bool) {
        if (isUpdate) {
            self.heightNextButtonConstraint.constant = 54
        } else {
            self.heightNextButtonConstraint.constant = 44
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationTitle()
        let userStatus: GATracking.UserStatus = AppManager.shared.userInfo.value == nil
            ? .other
            : .regular
        GATracking.scene(self.sceneType, params: [.userStatus(userStatus)])
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
    
    func setupUI() {
        webView.navigationDelegate = self
        self.setupBarItem(traitCollection: self.traitCollection)
        
        // setup progress bar
        self.containerWebview.addSubview(progressBar)

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.leftAnchor.constraint(equalTo: webView.leftAnchor),
            progressBar.rightAnchor.constraint(equalTo: webView.rightAnchor),
            progressBar.topAnchor.constraint(equalTo: webView.safeAreaLayoutGuide.topAnchor)
        ])
        // to update progress bar's value
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    func loadRequest() {
        guard let url = URL(string: GlobalConstant.premiumURl) else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringCacheData
        webView.load(request)
    }
    
    func bindViewModel() {
        self.restoreButton.isHidden = AppManager.shared.userInfo.value == nil
        bottomButtonSpacing.constant = AppManager.shared.userInfo.value == nil ? 0 : 15
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
        
        let restorePurchaseFail = NotificationCenter.default.rx
            .notification(.IAPHelperEndRestoreWithNoItem)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let input = RequestPremiumViewModel.Input(
            loadData: Driver.just(()),
            nextTrigger: nextButton.rx.tap.asDriver(),
            dismissTrigger: self.btDismiss.rx.tap.asDriver(),
            purcharseSucceed: purchaseSucceed,
            useInfo: AppManager.shared.userInfo.asDriver(),
            privacyTrigger: privacyButton.rx.tap.asDriver(),
            termTrigger: termButton.rx.tap.asDriver(),
            restoreTrigger: restoreButton.rx.tap.asDriver(),
            restorePurcharseFail: restorePurchaseFail
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
        output.loginAction.drive().disposed(by: disposeBag)
        output.userPaidAction.drive().disposed(by: disposeBag)
        output.restoreAction.drive().disposed(by: disposeBag)
        output.result.drive().disposed(by: disposeBag)
        output.errorBillingHandler.drive().disposed(by: disposeBag)
        output.restorePurcharseFailAction.drive().disposed(by: disposeBag)
        output.loading
            .drive(onNext: {[weak self] show in
                if show {
                    GooLoadingViewController.shared.show()
                } else if self?.isIPAInProccess == false {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.turnOffFlagIPA
            .drive(onNext: {[weak self] _ in
                self?.isIPAInProccess = false
            })
            .disposed(by: self.disposeBag)
        
        output.forceHideIndicator
            .drive(onNext: { _ in
                GooLoadingViewController.shared.hide()
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
        
        output.titleButtonRegister
            .drive(onNext: { [weak self] (billingText) in
                guard let self = self, let billingText = billingText else { return }
                self.handleDisplayNextButton(billingText: billingText)
            })
            .disposed(by: self.disposeBag)
        
        output.showAlertLogin.drive().disposed(by: self.disposeBag)
        
        tracking()
    }

    private func tracking() {
        GATracking.scene(self.sceneType)
        nextButton.rx.tap
            .bind(onNext: {
                if AppManager.shared.userInfo.value == nil {
                    GATracking.tap(.tapLoginForPremium)
                } else {
                    GATracking.tap(.tapRegister)
                }
            })
            .disposed(by: self.disposeBag)
        
        self.btDismiss.rx.tap
            .bind(onNext: {
                if AppManager.shared.userInfo.value == nil {
                    GATracking.tap(.tapLoginForPremiumClose)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressBar.progress = Float(webView.estimatedProgress)
        }
    }
    
    deinit {
        print("premium deinit")
    }
}

// MARK: - WKNavigationDelegate
extension RequestPremiumViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressBar.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressBar.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressBar.isHidden = true
    }
}
