//
//  WebViewController.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import WebKit
import GooidSDK
import RxCocoa
import RxSwift

class WebViewController: BaseViewController {
    
    enum OpenFrom {
        case dictionary, otther
        case requestPremium
        case draft
        case suggestion
    }
    
    struct Constant {
        static let padHorizontalPadding: CGFloat = 128
        static let detailWeb = "/word"
        static let domain = "\(Environment.wvScheme + Environment.wvHost)"
        static let detailWebThsrs = "/thsrs/"
    }
    
    // MARK: - UI
    var webView: WKWebView!
    var lessTrailing: NSLayoutConstraint!
    var lessLeading: NSLayoutConstraint!
    
    // MARK: - Data
    let startURL :URL
    let cachePolicy: URLRequest.CachePolicy
    let handleLinkBlock: ((URL) -> Bool)?
    var allowOrientation: UIInterfaceOrientationMask = .all
    var openFrom: OpenFrom = .otther
    var viewModel: WebViewVM!
    
    private let toastMessageFix = ToastMessageFixView.loadXib()
    private let eventTapToastView: PublishSubject<ToastMessageFixView.TapAction> = PublishSubject.init()
    private let eventDetailWebview: PublishSubject<Bool> = PublishSubject.init()
    private let eventLoadNotifyWebView: PublishSubject<Void> = PublishSubject.init()
    let eventDismiss: PublishSubject<Void> = PublishSubject.init()
    let detectUrlWebviewShouldLoad: PublishSubject<URL?> = PublishSubject.init()

    
    lazy var progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.progressTintColor = Asset.highlight.color
        return view
    }()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Life cycle
    init(url: URL,
         cachePolicy: URLRequest.CachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy,
         handleLinkBlock: ((URL) -> Bool)? = nil) {
        self.startURL = url
        self.cachePolicy = cachePolicy
        self.handleLinkBlock = handleLinkBlock
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createWebView()
        setupUI()
        loadRequest()
        tracking()
        bindViewModel()
    }
    
    // MARK: - Funcs
    func createWebView() {
        webView = WKWebView()
        webView.customUserAgent = GlobalConstant.userAgent
        webView.tintColor = Asset.selectionSecondary.color
        webView.tintColorDidChange()
        webView.backgroundColor = .white
    }
    
    func setupUI() {
        view.backgroundColor = Asset.white111111.color
        
        // setup webview
        self.view.addSubview(webView)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        self.view.safeAreaLayoutGuide.trailingAnchor
            .constraint(greaterThanOrEqualTo: self.webView.trailingAnchor)
            .active(with: .defaultHigh)
        
        lessTrailing = self.view.safeAreaLayoutGuide.trailingAnchor
            .constraint(lessThanOrEqualTo: self.webView.trailingAnchor)
            .active(with: .defaultHigh)
        
        self.webView.leadingAnchor
            .constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor)
            .active(with: .defaultHigh)
        
        lessLeading = self.webView.leadingAnchor
            .constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.leadingAnchor)
            .active(with: .defaultHigh)
        
        self.webView.widthAnchor
            .constraint(equalTo: self.view.heightAnchor)
            .active(with: .defaultLow)
        
        NSLayoutConstraint.activate([
            self.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // setup progress bar
        self.view.addSubview(progressBar)

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.leftAnchor.constraint(equalTo: webView.leftAnchor),
            progressBar.rightAnchor.constraint(equalTo: webView.rightAnchor),
            progressBar.topAnchor.constraint(equalTo: webView.safeAreaLayoutGuide.topAnchor)
        ])
        // to update progress bar's value
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        //update constraint for Orientation
        updatePaddingConstraint(size: self.view.bounds.size)
        
        self.toastMessageFix.delegate = self
    }
    
    private func tracking() {
        GATracking.scene(self.sceneType)
    }
    
    func loadRequest() {
        var request = URLRequest(url: startURL)
        request.cachePolicy = cachePolicy
        
        if shouldAddCookie() {
            if let cookie = GooidSDK.sharedInstance.generateCookiesIncludeBillingStatus()  {
                request.setValue(cookie, forHTTPHeaderField: "Cookie")
            }
        }
        webView.load(request)
    }
    
    private func shouldAddCookie() -> Bool {
        switch self.openFrom {
        case .dictionary:
            return true
            
        default: break
        }
        if sceneType == .searchResults || sceneType == .searchResultslnDraft {
            return true
        }
        return false
    }
    
    func bindViewModel() {
        let _ = NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .bind(onNext: { _ in self.eventLoadNotifyWebView.onNext(()) })
            .disposed(by: self.disposeBag)
        
        detectUrlWebviewShouldLoad
            .distinctUntilChanged()
            	.bind { [weak self] urlShouldLoad in
            guard let self = self, let url = urlShouldLoad else {
                return
            }
            self.detectDetailWebview(url: url)
        }.disposed(by: disposeBag)
        
        let eventLoadNotifyWebViewTrigger = Driver.merge(self.eventLoadNotifyWebView.asDriverOnErrorJustComplete(), Driver.just(()))
        
        let input = WebViewVM
            .Input(eventTapToastView: self.eventTapToastView.asDriverOnErrorJustComplete(),
                   eventDismiss: self.eventDismiss.asDriverOnErrorJustComplete(),
                   getNotifyWebTrigger: eventLoadNotifyWebViewTrigger)

        let output = viewModel.transform(input)
        
        let getBillingInfo = output.getBillingInfo
        let homeWebview = self.eventDetailWebview.asDriverOnErrorJustComplete()
                   
        Driver.combineLatest(getBillingInfo, homeWebview, output.getNotifyWeb).drive(onNext: { [weak self] (billingInfo, isDetail, notify) in
            guard let wSelf = self, wSelf.openFrom == .dictionary || wSelf.openFrom == .draft || wSelf.openFrom == .suggestion else { return }
             
            switch billingInfo.billingStatus {
            case .free:
                if let notify = notify {
                    wSelf.toastMessageFix.updateValue(notifyWeb: notify, size: wSelf.view.bounds.size)
                    
                    if AppSettings.showToastMgs.isShowView(version: notify.version ?? 0, spanDays: notify.spanDays ?? 0, isNotifWebView: true) && isDetail {
                        if (wSelf.toastMessageFix.isHidden) {
                            GATracking.scene(.billingAppeal)
                        }
                        wSelf.webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ToastMessageFixView.Constant.topDistance + ToastMessageFixView.Constant.bottomContraint, right: 0)
                        wSelf.toastMessageFix.addToParentView(view: wSelf.view)
                        wSelf.toastMessageFix.showView()
                        wSelf.toastMessageFix.applyShadow()
                    } else {
                        wSelf.toastMessageFix.hideView()
                    }
                }
            case .paid:
                wSelf.webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                wSelf.toastMessageFix.hideView()
            }
            

            
        }).disposed(by: disposeBag)
        
        //Skip with tha first load
        output.getBillingInfo
            .skip(1)
            .drive(onNext: { [weak self] billingInfo in
            guard let wSelf = self, wSelf.openFrom == .dictionary else { return }
                wSelf.loadRequest()
        }).disposed(by: disposeBag)
        
        output.eventTapToastView.drive(onNext: { [weak self] tap in
            guard let wSelf = self else { return }
            
            switch tap {
            case .close: wSelf.toastMessageFix.hideView()
            case .showRequestPrenium: break
            }
            
        }).disposed(by: disposeBag)
        
        output.eventDismiss.drive().disposed(by: disposeBag)
        output.showPremium.drive().disposed(by: disposeBag)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            print("estimated \(webView.estimatedProgress)")
            progressBar.progress = Float(webView.estimatedProgress)
        }
    }
    
    private func detectDetailWebview(url: URL) {
        let getText = url.absoluteString.enumerated()
            .filter{ $0.offset > Constant.domain.count - 1 && $0.offset <= (Constant.domain.count - 1 + Constant.detailWeb.count )}
            .map{ $0.element }.map{ String($0) }.joined()
        if getText == Constant.detailWeb {
            self.eventDetailWebview.onNext(true)
            self.eventLoadNotifyWebView.onNext(())
            return
        } else {
            self.eventDetailWebview.onNext(false)
        }
        
        self.detectUrlThsrs(url: url)
    }
    
    private func detectUrlThsrs(url: URL) {
        let textThsrs = url.absoluteString.enumerated()
            .filter{ $0.offset > Constant.domain.count - 1 + Constant.detailWebThsrs.count }
            .map{ $0.element }.map{ String($0) }.joined()
        if let idx = textThsrs.firstIndex(of: "/") {
            let pos = textThsrs.distance(from: textThsrs.startIndex, to: idx)
            let start = textThsrs.index(textThsrs.startIndex, offsetBy: 0)
            let end = textThsrs.index(textThsrs.startIndex, offsetBy: pos)
            let range = start..<end
            let strRange = String(textThsrs[range])
            if strRange.isNumber {
                let textFormat = "/thsrs/\(strRange)/meaning/"
                let textThsrs = url.absoluteString.enumerated()
                    .filter{ $0.offset > Constant.domain.count - 1 && $0.offset <= (Constant.domain.count - 1 + Constant.detailWebThsrs.count + (pos) + 9)}
                    .map{ $0.element }.map{ String($0) }.joined()
                if textFormat == textThsrs {
                    self.eventDetailWebview.onNext(true)
                } else {
                    self.eventDetailWebview.onNext(false)
                }
            }
        }
    }
    
    private func updatePaddingConstraint(size: CGSize) {
        let hRegular = (self.traitCollection.horizontalSizeClass == .regular)
        let vRegular = (self.traitCollection.verticalSizeClass == .regular)
        
        if hRegular && vRegular {
            self.lessLeading.constant = size.width < size.height ? 0 : Constant.padHorizontalPadding
            self.lessTrailing.constant = size.width < size.height ? 0 : Constant.padHorizontalPadding
        }
        
        self.updateViewConstraints()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePaddingConstraint(size: self.view.bounds.size)
        self.toastMessageFix.updatTextContent(size: self.view.bounds.size)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updatePaddingConstraint(size: self.view.bounds.size)
        self.toastMessageFix.updatTextContent(size: self.view.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updatePaddingConstraint(size: size)
        self.toastMessageFix.updatTextContent(size: size)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return allowOrientation
    }
}

// MARK: - WKUIDelegate
extension WebViewController: WKUIDelegate {
    //    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    //        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
    //            if UIApplication.shared.canOpenURL(url) {
    //                UIApplication.shared.open(url)
    //            }
    //        }
    //
    //        return nil
    //    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressBar.isHidden = true
        detectUrlWebviewShouldLoad.onNext(webView.url)
        // set dark mode on webview
//        let cssString = "@media (prefers-color-scheme: dark) {body {background-color: rgb(38,38,41); color: white;}a:link {color: #0096e2;}a:visited {color: #9d57df;}}"
//        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
//        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressBar.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressBar.isHidden = true
        print(error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            if handleLinkBlock?(url) == true {
                decisionHandler(.cancel)
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
extension WebViewController: ToastMessageFixViewDelegate {
    func tapAction(tap: ToastMessageFixView.TapAction) {
        self.eventTapToastView.onNext(tap)
        let action: GATracking.Tap
        if self.openFrom == .draft || self.sceneType == .searchResultslnDraft {
            action = tap == .close
            ? GATracking.Tap.searchResultsInPremiumInfoDraftClose
            : GATracking.Tap.searchResultsInPremiumInfoDraft
            GATracking.tap(action)
        } else if self.openFrom == .dictionary {
            action = tap == .close
            ? GATracking.Tap.searchResultsInPremiumInfoClose
            : GATracking.Tap.searchResultsInPremiumInfo
            GATracking.tap(action)
        }
    }
}
