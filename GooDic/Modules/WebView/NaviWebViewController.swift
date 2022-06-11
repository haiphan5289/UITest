//
//  NaviWebViewController.swift
//  GooDic
//
//  Created by ttvu on 6/16/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import WebKit
import GooidSDK
import RxSwift

class NaviWebViewController: WebViewController {
    
    struct Constant {
        static let buttonGap: CGFloat = 14.0
    }
    
    // MARK: - UI
    
    lazy var dismissButton: UIButton = {
        let activeImage = Asset.icDismiss.image
        let button = UIButton(frame: CGRect(origin: .zero, size: activeImage.size))
        button.setImage(activeImage, for: .normal)
        button.addTarget(self, action: #selector(dismissButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var previousButton: UIButton = {
        let activeImage = Asset.icPreviousB.image
        let inactiveImage = Asset.icPreviousA.image
        let button = UIButton(frame: CGRect(origin: .zero, size: activeImage.size))
        button.setImage(activeImage, for: .normal)
        button.setImage(inactiveImage, for: .disabled)
        button.addTarget(self, action: #selector(previousButtonPressed(_:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    lazy var nextButton: UIButton = {
        let activeImage = Asset.icNextB.image
        let inactiveImage = Asset.icNextA.image
        let button = UIButton(frame: CGRect(origin: .zero, size: activeImage.size))
        button.setImage(activeImage, for: .normal)
        button.setImage(inactiveImage, for: .disabled)
        button.addTarget(self, action: #selector(nextButtonPressed(_:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    lazy var leftButton: UIBarButtonItem = {
        previousButton.frame.origin = CGPoint(x: dismissButton.frame.maxX + Constant.buttonGap, y: 0)
        let width = previousButton.frame.maxX
        let height = dismissButton.bounds.height
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.addSubview(dismissButton)
        view.addSubview(previousButton)
        let button = UIBarButtonItem(customView: view)
        return button
    }()
    
    lazy var rightButton: UIBarButtonItem = {
        let width = 2 * nextButton.bounds.width + Constant.buttonGap
        let height = nextButton.bounds.height
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.addSubview(nextButton)
        let button = UIBarButtonItem(customView: view)
        return button
    }()
    
    
    // MARK: - Funcs
    override func createWebView() {
        let config = WKWebViewConfiguration()
        
        switch self.openFrom {
        case .dictionary:
            config.userContentController = userContentController()
        default: break
        }
        
        config.applicationNameForUserAgent = GlobalConstant.userAgent
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.tintColor = Asset.selectionSecondary.color
        webView.tintColorDidChange()
        webView.backgroundColor = .white
    }
    
    private func userContentController() -> WKUserContentController {
        let userContentController = WKUserContentController()
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            var cookiesUser = cookies
            if let cookie = GooidSDK.sharedInstance.generateCookies()  {
                let cookieHttp = HTTPCookie(properties: [
                    .name: "Cookie",
                    .value: cookie,
                    .originURL: startURL,
                    .path: "/",
                    .secure: "TRUE"
                ])
                if let cookie = cookieHttp {
                    cookiesUser.append(cookie)
                }
            }
            let script = getJSCookiesString(for: cookiesUser)
            let cookieScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            userContentController.addUserScript(cookieScript)
        }
        return userContentController
    }
    
    ///Generates script to create given cookies
    public func getJSCookiesString(for cookies: [HTTPCookie]) -> String {
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"

        for cookie in cookies {
            result += "document.cookie='\(cookie.name)=\(cookie.value); domain=\(cookie.domain); path=\(cookie.path); "
            if let date = cookie.expiresDate {
                result += "expires=\(dateFormatter.string(from: date)); "
            }
            if (cookie.isSecure) {
                result += "secure; "
            }
            result += "'; "
        }
        return result
    }
    
    override func setupUI() {
        super.setupUI()
        
        navigationItem.rightBarButtonItem = self.rightButton
        navigationItem.leftBarButtonItem = self.leftButton
        
        if #available(iOS 15.0, *) {
            let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 15)]
            navigationBarTitle.attributedText = NSAttributedString(string: self.title ?? "", attributes: atts)
            self.setupNavigationTitle(type: .naviWebview)
        } else {
            let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 15)]
            navigationBarTitle.attributedText = NSAttributedString(string: self.title ?? "", attributes: atts)
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barTintColor = Asset.naviBarBgModel.color
        }
        
        nextButton.isHidden = openFrom == .requestPremium
        previousButton.isHidden = openFrom == .requestPremium
    }
    
    @objc func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true) {
            self.eventDismiss.onNext(())
        }
    }
    
    @objc func previousButtonPressed(_ sender: Any) {
        webView.goBack()
        
        updateNaviButtonsState()
    }
    
    @objc func nextButtonPressed(_ sender: Any) {
        webView.goForward()
        
        updateNaviButtonsState()
    }
    
    func updateNaviButtonsState() {
        previousButton.isEnabled = webView.canGoBack
        nextButton.isEnabled = webView.canGoForward
    }
    
    deinit {
        let websiteDataTypes: NSSet = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
        ];
        let dateFrom: NSDate = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: dateFrom as Date, completionHandler: {() -> Void in
            // Done
        })
        UserDefaults.standard.synchronize()
    }

}

// MARK: - WKNavigationDelegate
extension NaviWebViewController {
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
        
        updateNaviButtonsState()
    }
    
    override func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        super.webView(webView, didStartProvisionalNavigation: navigation)
        updateNaviButtonsState()
    }
    
    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        super.webView(webView, didFail: navigation, withError: error)
        updateNaviButtonsState()
    }
    
    override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        super.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
        updateNaviButtonsState()
    }
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if self.openFrom == .requestPremium {
            super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
            return
        }
        switch navigationAction.navigationType {
        case .linkActivated:
            linkActivated(webView: webView, navigationAction: navigationAction, decisionHandler: decisionHandler)
        default:
            self.detectUrlWebviewShouldLoad.onNext(webView.url)
            otherAction(webView: webView, navigationAction: navigationAction, decisionHandler: decisionHandler)
        }
    }
    
    func linkActivated(webView: WKWebView, navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        guard allowLoadURL(url: url) else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func otherAction(webView: WKWebView, navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let isMainFrame = navigationAction.targetFrame?.isMainFrame, isMainFrame else {
            decisionHandler(.allow)
            return
        }
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        guard allowLoadURL(url: url) else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func allowLoadURL(url: URL) -> Bool {
        let domain = startURL.host ?? Environment.wvHost
        if let host = url.host, host.contains(domain) {
            return true
        }
        
        return false
    }
}
