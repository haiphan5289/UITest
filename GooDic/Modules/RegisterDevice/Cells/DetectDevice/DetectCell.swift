//
//  DetectCell.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class DetectCell: UITableViewCell {
    
    struct Constant {
        static let limitDevice: Int = GlobalConstant.limitDevice
    }

    var moveToMain: (()-> Void)?
    var moveToRegister: (()-> Void)?
    @IBOutlet weak var stackViewLabel: UIStackView!
    private let lbRegister: UILabel = UILabel(frame: .zero)
    private let lbRemove: UILabel = UILabel(frame: .zero)
    private let lbInstall: UILabel = UILabel(frame: .zero)
    @IBOutlet weak var imgDevice: UIImageView!
    @IBOutlet weak var btNotRegister: UIButton!
    @IBOutlet weak var btRegister: UIButton!
    @IBOutlet weak var lbModelName: UILabel!
    @IBOutlet weak var viewInfo: UIView!
    @IBOutlet weak var bottomStackView: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        setupRX()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    private func setupRX() {
        self.btNotRegister.rx.tap.bind { [weak self] in
            guard let wSelf = self else {
                return
            }
            wSelf.moveToMain?()
        }.disposed(by: disposeBag)
        
        self.btRegister.rx.tap.bind { [weak self] _ in
            guard let wSelf = self else {
                return
            }
            wSelf.moveToRegister?()
        }.disposed(by: disposeBag)
    }
    func setupUI(hasRegister: Bool, count: Int, type: RouteLogin) {
        switch type {
        case .menu, .cloudDraft, .cloudFolder, .cloudFolderSelection, .cloud:
            self.btNotRegister.isHidden = true
        default:
            self.btNotRegister.isHidden = false
        }
        
        self.setupStackViewLabel(count: count)
        guard hasRegister else {
            self.updateLayoutNotHas(count: count, type: type)
            
            if AppManager.shared.billingInfo.value.billingStatus == .free {
                switch type {
                case .menu, .cloud, .cloudDraft, .cloudFolder, .cloudFolderSelection:
                    self.bottomStackView.constant = (count >= 2) ? 0 : 20
                default:
                    self.bottomStackView.constant = 20
                }
            } else {
                self.bottomStackView.constant = 20
            }
            self.viewInfo.isHidden = false
            return
        }
        
        let views = [self.viewInfo, self.btRegister, self.btNotRegister]
        views.forEach { (v) in
            v?.isHidden = true
        }
        
        if !(AppManager.shared.billingInfo.value.billingStatus == .free
             && count > Constant.limitDevice) {
            lbRemove.removeFromSuperview()
        }
        
        self.bottomStackView.constant = 4
    }
    private func updateLayoutNotHas(count: Int, type: RouteLogin) {
        switch count {
        case let x where x < Constant.limitDevice:
            lbRemove.text = ""
            self.btRegister.isHidden = false
            self.btNotRegister.isHidden = false
        case let x where x == Constant.limitDevice:
            
            if AppManager.shared.billingInfo.value.billingStatus == .free {
                lbRemove.attributedText = self.getAttributeString(
                    text: L10n.RegisterDevices.registertwodevice,
                    color: Asset.textRemoveDevice.color
                )
                self.btRegister.isHidden = true
                switch type {
                case .menu, .cloudDraft, .cloudFolder, .cloudFolderSelection, .cloud, .detecStatusUser:
                    self.btNotRegister.isHidden = true // already has back button
                default:
                    self.btNotRegister.isHidden = false
                }
            } else {
                lbRemove.text = ""
                self.btRegister.isHidden = false
                self.btNotRegister.isHidden = false
            }
            
        default:
            if AppManager.shared.billingInfo.value.billingStatus == .free {
                lbRemove.attributedText = self.getAttributeString(
                    text: L10n.RegisterDevices.registergreaterthantwodevice,
                    color: Asset.textRemoveDevice.color
                )
                self.btRegister.isHidden = true
                self.btNotRegister.isHidden = true
            } else {
                lbRemove.text = ""
                self.btRegister.isHidden = false
                self.btNotRegister.isHidden = false
            }
        }
        
        switch type {
        case .menu, .cloudDraft, .cloudFolder, .cloudFolderSelection, .cloud:
            self.btNotRegister.isHidden = true
        default: break
        }
        
//        guard count == 2 else {
//            lbRemove.text = ""
//            self.btRegister.isHidden = false
//            return
//        }
    }
    func setupLayout(count: Int, status: BillingStatus) {
        if count > 2 && status == .free {
            self.btNotRegister.isHidden = true
        } else {
            self.btNotRegister.isHidden = false
        }
    }
    private func setupStackViewLabel(count: Int) {
        for view in self.stackViewLabel.subviews{
            view.removeFromSuperview()
        }
        
        lbRegister.font = UIFont.hiraginoSansW4(size: 14)
        
        
        
        switch AppManager.shared.billingInfo.value.billingStatus {
        case .paid:
            lbRegister.attributedText = self.getAttributeString(text: L10n.RegisterDevices.subscribed,
                                                                color: Asset.textPrimary.color)
        default:
            lbRegister.attributedText = self.getAttributeString(text: L10n.RegisterDevices.limitDevices,
                                                                color: Asset.textPrimary.color)
        }
        
        
        lbRegister.numberOfLines = 0
        self.stackViewLabel.addArrangedSubview(lbRegister)
        if count == Constant.limitDevice {
            lbRemove.attributedText = self.getAttributeString(text: L10n.RegisterDevices.registertwodevice,
                                                              color: Asset.textRemoveDevice.color)
            lbRemove.font = UIFont.hiraginoSansW6(size: 14)
            lbRemove.numberOfLines = 0
            self.stackViewLabel.addArrangedSubview(lbRemove)
        } else if count > Constant.limitDevice {
            lbRemove.attributedText = self.getAttributeString(
                text: L10n.RegisterDevices.registergreaterthantwodevice,
                color: Asset.textRemoveDevice.color
            )
            lbRemove.font = UIFont.hiraginoSansW6(size: 14)
            lbRemove.numberOfLines = 0
            self.stackViewLabel.addArrangedSubview(lbRemove)
        }
    }
    
    func addTextInstall(isInstall: Bool, count: Int) {
        guard isInstall && self.viewInfo.isHidden == false else {
            return
        }
        lbInstall.numberOfLines = 0
        lbInstall.textColor = Asset.textPrimary.color
        lbInstall.font = UIFont.hiraginoSansW6(size: 14)
        lbInstall.attributedText = self.getAttributeString(text: L10n.ListDevivice.MessageError.install,
                                                            color: Asset.textRemoveDevice.color)
        self.stackViewLabel.addArrangedSubview(lbInstall)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateDarkMode()
    }
    
    private func updateDarkMode() {
        let views = [self.btNotRegister, self.btRegister]
        
        views.forEach { (bt) in
            bt?.layer.borderColor = Asset.borderButtonListDevice.color.cgColor
        }
    }
    
    private func getAttributeString(text: String, color: UIColor) -> NSAttributedString {
        let text = text
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        
        let attr = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key.foregroundColor: color,
//            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 14),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])
        
        return attr
    }
}
