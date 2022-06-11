//
//  AgreementViewController.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

class AgreementViewController: BaseViewController, ViewBindableProtocol {

    struct Constant {
        static let shadowColor = Asset.separator.color
        static let shadowOffset = CGSize(width: 0, height: -1)
        static let shadowOpacity: Float = 1
    }
    
    // MARK: - UI
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var agreementButton: UIButton!
    @IBOutlet weak var disagreementButton: UIButton!
    
    lazy var progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.progressTintColor = Asset.highlight.color
        return view
    }()
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: AgreementViewModel!
    var clickURLTrigger = PublishSubject<URL>()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupCosmetic()
        setupUI()
    }
    
    // MARK: - Funcs
    private func setupCosmetic() {
        bottomView.layer.shadowColor = Constant.shadowColor.cgColor
        bottomView.layer.shadowOffset = Constant.shadowOffset
        bottomView.layer.shadowOpacity = Constant.shadowOpacity
    }
    
    private func setupUI() {
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
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
        
        if let url = URL(string: GlobalConstant.agreementURL) {
            load(url: url)
        }
    }
    
    func bindViewModel() {
        let loadTrigger = webView.rx.didStartLoad.asDriverOnErrorJustComplete().mapToVoid()
        let finishTrigger = webView.rx.didFinishLoad.asDriverOnErrorJustComplete().mapToVoid()
        
        let input = AgreementViewModel.Input(loadTrigger: loadTrigger,
                                         finishLoadTrigger: finishTrigger,
                                         agreeTrigger: agreementButton.rx.tap.asDriver(),
                                         disagreeTrigger: disagreementButton.rx.tap.asDriver(),
                                         clickURLTrigger: clickURLTrigger.asDriverOnErrorJustComplete())
        
        let output = viewModel.transform(input)
        
        output.finishedLoad
            .startWith(false)
            .drive(agreementButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
        output.finishedLoad
            .startWith(false)
            .map({ $0 ? Asset.highlight.color : Asset.separator.color })
            .drive(agreementButton.rx.backgroundColor)
            .disposed(by: self.disposeBag)
        
        output.clickedURL
            .drive()
            .disposed(by: self.disposeBag)
        
        output.agreed
            .drive()
            .disposed(by: self.disposeBag)
        
        output.disagreed
            .drive()
            .disposed(by: self.disposeBag)
        
        tracking()
    }
    
    private func tracking() {
        GATracking.scene(self.sceneType)
    }
    
    private func load(url: URL) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringCacheData
        webView.customUserAgent = GlobalConstant.userAgent
        webView.load(request)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            print("estimated \(webView.estimatedProgress)")
            progressBar.progress = Float(webView.estimatedProgress)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}


extension AgreementViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // open the link has the "target="_blank"" attribute.
        if navigationAction.targetFrame == nil {
            if let url = navigationAction.request.url {
                clickURLTrigger.onNext(url)
            }
        }
        
        return nil
    }
}

extension AgreementViewController: WKNavigationDelegate {
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
        print(error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            clickURLTrigger.onNext(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
