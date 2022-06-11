//
//  UserInfoViewController.swift
//  GooDic
//
//  Created by ttvu on 11/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

class UserInfoViewController: UIViewController {
    
    struct Constant {
        static let loginHeight: CGFloat = 159
        static let logoutHeight: CGFloat = 95.0
        static let premiumHeight: CGFloat = 199.0
    }

    // MARK: - UI
    @IBOutlet weak var gooIdLabel: UILabel!
    @IBOutlet weak var actionButton: BorderButton!
    @IBOutlet weak var addDeviceButton: BorderButton!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var registeredDeviceImage: UIImageView!
    @IBOutlet weak var devicesView: UIView!
    @IBOutlet weak var infoStackView: UIStackView!
    @IBOutlet weak var premiumInfoView: UIView!
    @IBOutlet weak var actionInfoButton: UIButton!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var bottomBorderView: NSLayoutConstraint!
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var userInfo: UserInfo? = nil {
        didSet {
            updateUI(with: userInfo)
        }
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        tracking()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateUI(with: userInfo)
    }
    
    // MARK: - Funcs
    private func setupUI() {
        devicesView.addSeparator(at: .top, color: Asset.separator.color)
    }
    
    private func updateUI(with userInfo: UserInfo?) {
        if let userInfo = userInfo {
            // log in
            actionButton.borderColor = Asset.textSecondary.color
            actionButton.setTitle(L10n.Account.logout, for: .normal)
            actionButton.setImage(Asset.icLogout.image, for: .normal)
            actionButton.setTitleColor(Asset.textSecondary.color, for: .normal)
            gooIdLabel.text = userInfo.name.isEmpty ? L10n.Menu.cannotGetInfo : userInfo.name
            self.infoStackView.arrangedSubviews[1].isHiddenInStackView = (userInfo.billingStatus ?? .free) == .free
            self.premiumInfoView.subviews.forEach {
                $0.isHidden = (userInfo.billingStatus ?? .free) == .free
            }
            bottomSeparatorView.isHidden = (userInfo.billingStatus ?? .free) == .free
            switch userInfo.deviceStatus {
            case .registered:
                deviceLabel.text = L10n.Menu.registeredDevice
//                registeredDeviceImage.image = Asset.icDeviceNow.image
            case .unregistered:
                deviceLabel.text = L10n.Menu.unregisteredDevice
//                registeredDeviceImage.image = Asset.icDevice.image
            case .unknown:
                deviceLabel.text = L10n.Menu.cannotGetInfo
            }
            
        } else {
            // log out
            self.infoStackView.arrangedSubviews[1].isHiddenInStackView = true
            actionButton.borderColor = Asset.highlight.color
            actionButton.setTitle(L10n.Account.login, for: .normal)
            actionButton.setImage(Asset.icLogin.image, for: .normal)
            actionButton.setTitleColor(Asset.highlight.color, for: .normal)
            gooIdLabel.text = L10n.Menu.noAccount
            bottomSeparatorView.isHidden = true
        }
        
    }
    
    func updateViewPrenium(userInfo: UserInfo?) {
        guard let user = userInfo else {
            self.bottomBorderView.priority = .defaultHigh
            return
        }
        
        if user.billingStatus == .paid {
            self.bottomBorderView.priority = .defaultLow
        } else {
            self.bottomBorderView.priority = .defaultHigh
        }
        
        self.view.layoutIfNeeded()
    }
    
    
    var targetContentSize: CGSize {
        if self.userInfo != nil {
            if (self.userInfo?.billingStatus ?? .free) == .paid {
                return CGSize(width: view.bounds.width, height: Constant.premiumHeight)
            }
            return CGSize(width: view.bounds.width, height: Constant.loginHeight)
        } else {
            return CGSize(width: view.bounds.width, height: Constant.logoutHeight)
        }
    }
    
    private func tracking() {
        let trackLoginLogout = actionButton.rx.tap
            .map({ [weak self] _ -> GATracking.Tap in
                return self?.actionButton.title(for: .normal) == L10n.Account.login ? .tapLogin : .tapLogout
            })
        
        let trackAddDevice = addDeviceButton.rx.tap
            .map({ GATracking.Tap.tapRegisterDevice })
        
        Observable.merge(trackLoginLogout, trackAddDevice)
            .subscribe(onNext: { event in
                GATracking.tap(event, params: [.screenName(L10n.ScreenName.screenMenu)])
            })
            .disposed(by: self.disposeBag)
    }
}
