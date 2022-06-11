//
//  RegistrationLogoutViewController.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RegistrationLogoutViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let spacing: CGFloat = 128
    }

    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var imgLogOut: UIImageView!
    @IBOutlet weak var rightViewContent: NSLayoutConstraint!
    @IBOutlet weak var leftViewContent: NSLayoutConstraint!
    
    private let gooIdView: GooIDView = GooIDView.loadXib()
    private var displayViewDidLayout: PublishSubject<Bool> = PublishSubject.init()
    let disposeBag = DisposeBag()
    var viewModel: RegistrationLogoutViewModel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
extension RegistrationLogoutViewController {
    // MARK: - Funcs
    private func setupUI() {
        gooIdView.translatesAutoresizingMaskIntoConstraints = false
        self.vContent.addSubview(gooIdView)
        
        gooIdView.leftAnchor.constraint(equalTo: self.vContent.leftAnchor).isActive = true
        gooIdView.rightAnchor.constraint(equalTo: self.vContent.rightAnchor).isActive = true
        gooIdView.topAnchor.constraint(equalTo: self.imgLogOut.bottomAnchor, constant: 10).isActive = true
        gooIdView.heightAnchor.constraint(equalToConstant: 114).isActive = true
        
//        gooIdView.viewTitle.isHidden = true
        
        gooIdView.btNotLogin.backgroundColor = Asset.buttonNotRegister.color
        gooIdView.btNotLogin.setTitleColor(Asset.textButtonDoNotRegister.color, for: .normal)
        gooIdView.btNotLogin.layer.borderColor = Asset.borderButtonDoNotRegister.color.cgColor
        gooIdView.updateUIForceUpdate()
                
        tracking()
    }
    func bindViewModel() {
        let login = self.gooIdView.btLogin.rx.tap.map { TypeGooIDSKD.login }
        let ignore = self.gooIdView.btNotLogin.rx.tap.map { TypeGooIDSKD.ignore }
        let tap = Observable.merge(login, ignore).asDriverOnErrorJustComplete()
        
        let input = RegistrationLogoutViewModel
            .Input(tapAction: tap)
        let output = viewModel.transform(input)
        
        displayViewDidLayout
            .take(1)
            .asObservable()
            .bind { [weak self] (isShow) in
                guard let self = self else { return }
                if isShow {
                    self.updateLayoutIPad()
                }
        }.disposed(by: disposeBag)
        
        output.tapToMain
            .drive()
            .disposed(by: self.disposeBag)
                
        output.result
            .drive()
            .disposed(by: self.disposeBag)
        output.checkBillingStatusAction
            .drive()
            .disposed(by: self.disposeBag)
        output.errorBillingHandler
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loading
            .do { loading in
                loading ?  GooLoadingViewController.shared.show() : GooLoadingViewController.shared.hide()
            }
            .drive()
            .disposed(by: self.disposeBag)
        
    }
    private func tracking() {
        // Tracking Tap events
        self.gooIdView.btLogin.rx.tap.bind { _ in
            GATracking.tap(.tapLogin, params: [.screenName(RouteLogin.forceLogout.screenName)])
        }.disposed(by: disposeBag)
        
        GATracking.scene(sceneType)
    }
    
    private func updateLayoutIPad() {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            let size = self.view.bounds
            let isLandscape = (size.height < size.width) ? true : false
            self.leftViewContent.constant = (isLandscape) ? Constant.spacing : 0
            self.rightViewContent.constant = (isLandscape) ? Constant.spacing : 0
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        gooIdView.btNotLogin.layer.borderColor = Asset.borderButtonDoNotRegister.color.cgColor
    }

}
