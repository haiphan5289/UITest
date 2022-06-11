//
//  FeedbackViewController.swift
//  GooDic
//
//  Created by ttvu on 6/17/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import WebKit

class FeedbackViewController: WebViewController {
    
    // MARK: - UI
    private var dismissButton: UIBarButtonItem = UIBarButtonItem.createDismissButton()
    
    // MARK: - Life cycle
    override func createWebView() {
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = GlobalConstant.userAgent
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.tintColor = Asset.selectionSecondary.color
        webView.tintColorDidChange()
        webView.backgroundColor = .white
    }
    
    override func setupUI() {
        super.setupUI()
        
        // setup dismiss button
        self.navigationItem.leftBarButtonItem = dismissButton
        dismissButton.target = self
        dismissButton.action = #selector(dismissButtonPressed(_:))
        self.navigationItem.leftBarButtonItem?.tintColor = Asset.textPrimary.color
        
        self.setupNavigationTitle(type: .feedBackWebView)
    }
    
    @objc func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
