//
//  LoginViewController.swift
//  GooDic
//
//  Created by paxcreation on 11/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GooidSDK

enum TypeGooIDSKD {
    case login
    case register
    case ignore
}

class LoginViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let spacing: CGFloat = 128
    }

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var vRegister: UIView!
    @IBOutlet weak var btSignUp: UIButton!
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var leftViewContent: NSLayoutConstraint!
    @IBOutlet weak var rightViewContent: NSLayoutConstraint!
    
    private let gooIdView: GooIDView = GooIDView.loadXib()
    private var loginSuccess: PublishSubject<Void> = PublishSubject.init()
    private var viewDidApear: PublishSubject<Void> = PublishSubject.init()
    private var displayViewDidLayout: PublishSubject<Bool> = PublishSubject.init()
    let disposeBag = DisposeBag()
    var routeLogin: RouteLogin = .login
    var viewModel: LoginViewModel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.updateLayoutIPad()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        displayViewDidLayout.onNext(true)
    }

}
extension LoginViewController {
    // MARK: - Funcs
    private func setupUI() {
        gooIdView.btNotLogin.isHidden = false
        gooIdView.translatesAutoresizingMaskIntoConstraints = false
        self.vContent.addSubview(gooIdView)
        
        gooIdView.leftAnchor.constraint(equalTo: self.vContent.leftAnchor).isActive = true
        gooIdView.rightAnchor.constraint(equalTo: self.vContent.rightAnchor).isActive = true
        gooIdView.topAnchor.constraint(equalTo: self.vRegister.bottomAnchor, constant: 16).isActive = true
//        gooIdView.bottomAnchor.constraint(equalTo: self.vContent.bottomAnchor, constant: -88).isActive = true
        
        switch self.routeLogin {
        case .app, .login, .menu, .tutorial:
            gooIdView.btNotLogin.isHidden = false
        case .cloudDraft, .cloudFolder, .cloudFolderSelection:
            gooIdView.btNotLogin.isHidden = true
        default:
            break
        }
        
        tracking()
        
        updateDarkMode()
    }
    private func tracking() {
//         Tracking Tap events
        let tapSignUp = btSignUp.rx.tap
            .map({ GATracking.Tap.tapSignUp })

        let tapLogin = self.gooIdView.btLogin.rx.tap
            .map({ GATracking.Tap.tapLogin })

        Observable.merge(tapSignUp, tapLogin)
            .bind(onNext: { [weak self] (tap) in
                guard let wSelf = self else {
                    return
                }
                var screenName = ""
                switch wSelf.routeLogin {
                case .app, .tutorial, .login:
                    screenName = L10n.ScreenName.screenLogin
                default:
                    screenName = wSelf.routeLogin.screenName
                }
                GATracking.tap(tap, params: [.screenName(screenName)])
            })
            .disposed(by: self.disposeBag)
        
        GATracking.scene(sceneType)
    }
    func bindViewModel() {
        let login = self.gooIdView.btLogin.rx.tap.map { TypeGooIDSKD.login }
        let register = self.btSignUp.rx.tap.map { TypeGooIDSKD.register }
        let ignore = self.gooIdView.btNotLogin.rx.tap.map { TypeGooIDSKD.ignore }
        
        let tap = Observable.merge(login, register, ignore)
            .asDriverOnErrorJustComplete()
        
        let input = LoginViewModel.Input(tapAction: tap)
        let output = viewModel.transform(input)
        
        output.tap
            .drive()
            .disposed(by: self.disposeBag)
        
        displayViewDidLayout
            .take(1)
            .asObservable()
            .bind { [weak self] (isShow) in
                guard let self = self else { return }
                if isShow {
                    self.updateLayoutIPad()
                }
        }.disposed(by: disposeBag)
        
        
        output.loading
            .do { loading in
                //hide icon loading
//                loading ?  GooLoadingViewController.shared.show() : GooLoadingViewController.shared.hide()
                
                //load api and don't allow user touch anymore
                self.view.isUserInteractionEnabled = !loading
            }
            .drive()
            .disposed(by: self.disposeBag)
        
        output.result
            .drive()
            .disposed(by: self.disposeBag)
        
        output.err
            .drive()
            .disposed(by: self.disposeBag)
        
        output.errNetwork
            .drive()
            .disposed(by: self.disposeBag)
        
        output.doErrorListDevice
            .drive()
            .disposed(by: self.disposeBag)
        
        output.checkRegisterMenuScreen
            .drive()
            .disposed(by: self.disposeBag)
        
        output.checkRegisterCannotBeUpdate
            .drive()
            .disposed(by: self.disposeBag)
        
        output.updateWaitingAPI
            .drive()
            .disposed(by: self.disposeBag)
        
        output.retryListDevice
            .drive()
            .disposed(by: self.disposeBag)
        
        output.checkBillingAction
            .drive()
            .disposed(by: self.disposeBag)
        output.errorBillingHandle
            .drive()
            .disposed(by: self.disposeBag)
        
        output.doMoveToDevicesWithCaseOverLimit
            .drive()
            .disposed(by: self.disposeBag)
    }
    
    private func updateDarkMode() {
        switch self.routeLogin {
        case .cloudFolderSelection:
            let views = [self.scrollView, self.vContent, self.vRegister, self.gooIdView, self.gooIdView.viewContent]
            views.forEach { (v) in
                v?.backgroundColor = Asset.cellBackground.color
            }
                
        default:
            self.gooIdView.btNotLogin.layer.borderColor = Asset.borderButtonListDevice.color.cgColor
        }
        
    }
    
    private func updateLayoutIPad() {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            switch self.routeLogin {
            case .app, .tutorial, .login, .menu:
                let size = self.view.bounds.size
                let isLandscape = (size.height < size.width) ? true : false
                self.leftViewContent.constant = (isLandscape) ? Constant.spacing : 0
                self.rightViewContent.constant = (isLandscape) ? Constant.spacing : 0
            default:
                break
            }
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDarkMode()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
