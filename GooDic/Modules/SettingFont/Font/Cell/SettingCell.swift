//
//  SettingCell.swift
//  GooDic
//
//  Created by paxcreation on 5/19/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

class SettingCell: UITableViewCell {
    
    enum TapSetting {
        case increase, decrease, hiraginoSans, hiraginoMincho
    }
    
    var showAlertAutoSave: ((Bool) -> Void)?
    var updateSettingFont:((SettingFont) -> Void)?
    var actionShare:(() -> Void)?
    
    private let disposeBag = DisposeBag()
    @IBOutlet weak var vFontSize: UIView!
    @IBOutlet weak var btIncreaseFont: UIButton!
    @IBOutlet weak var btDecreaseFont: UIButton!
    @IBOutlet weak var lbValueFont: UILabel!
    @IBOutlet weak var vFont: UIView!
    @IBOutlet weak var btHiraginoMincho: UIButton!
    @IBOutlet weak var btHiraginoSans: UIButton!
    @IBOutlet weak var vShare: UIView!
    @IBOutlet weak var btShare: UIButton!
    @IBOutlet weak var lbMinus: UILabel!
    @IBOutlet weak var lbPlus: UILabel!
    @IBOutlet weak var autoSaveView: UIView!
    @IBOutlet weak var autoSaveSwitch: UISwitch!
    
    private var settingFont: SettingFont?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupUI()
        self.setupRX()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let s = self.settingFont {
            self.updateUIFont(setting: s)
        }
    }
    
}
extension SettingCell {
    
    private func setupUI() {
        self.autoSaveSwitch.clipsToBounds = true
        self.autoSaveSwitch.layer.cornerRadius = self.autoSaveSwitch.frame.height / 2
        
        self.vFont.addSeparator(at: .bottom, color: Asset.modelCellSeparator.color)
        self.vFontSize.addSeparator(at: .bottom, color: Asset.modelCellSeparator.color)
        self.autoSaveView.addSeparator(at: .bottom, color: Asset.modelCellSeparator.color)
    }
    
    private func setupRX() {
        
        let increase = self.btIncreaseFont.rx.tap.map{ TapSetting.increase }
        let decrease = self.btDecreaseFont.rx.tap.map{ TapSetting.decrease }
        let fontSans = self.btHiraginoSans.rx.tap.map{ TapSetting.hiraginoSans }
        let fontMinCho = self.btHiraginoMincho.rx.tap.map{ TapSetting.hiraginoMincho }
        
        Observable.merge(increase, decrease, fontSans, fontMinCho)
            .bind { [weak self] (tap) in
                guard let wSelf = self, let s = wSelf.settingFont else { return }
                var setting: SettingFont? = s
                switch tap {
                case .increase:
                    setting = wSelf.updateIncrease(setting: s)
                    
                case .decrease:
                    setting = wSelf.updateDecrease(setting: s)
                    
                case .hiraginoSans:
                    setting = SettingFont(size: s.size, name: NameFont.hiraginoSansW4, isEnableButton: s.isEnableButton, autoSave: s.autoSave ?? false)
                case .hiraginoMincho:
                    setting = SettingFont(size: s.size, name: NameFont.hiraginoMinchoW3, isEnableButton: s.isEnableButton, autoSave: s.autoSave ?? false)
                }
                if let s = setting {
                    wSelf.changeValueSetting(setting: s)
                }
            }.disposed(by: disposeBag)
        
        self.btShare.rx.tap.bind { _ in
            self.actionShare?()
        }.disposed(by: disposeBag)
        
        self.autoSaveSwitch.rx.controlEvent(.valueChanged).bind { [weak self] _ in
            guard let wSelf = self, let settting = wSelf.settingFont else { return }
            let s = SettingFont(size: settting.size, name: settting.name, isEnableButton: settting.isEnableButton, autoSave: wSelf.autoSaveSwitch.isOn)
            //Animation of Switch is smooth better.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                wSelf.changeValueSetting(setting: s)
            }
            
            wSelf.showAlertAutoSave?(wSelf.autoSaveSwitch.isOn)
            
        }.disposed(by: disposeBag)
        
    }
    
    private func changeValueSetting(setting: SettingFont) {
        self.settingFont = setting
        self.updateUIFont(setting: setting)
        self.updateSettingFont?(setting)
        AppSettings.settingFont = setting
    }
    
    private func updateDecrease(setting: SettingFont) -> SettingFont? {
        guard let index = SizeFont.allCases.firstIndex(of: setting.size) else { return nil}
    
        switch setting.size {
        case .eighty:
            let imgPlus = Asset.icMinusInactive.image
            self.btDecreaseFont.setImage(imgPlus, for: .normal)
            return nil
        default:
            let s = SettingFont(size: SizeFont.allCases[index - 1], name: setting.name, isEnableButton: setting.isEnableButton, autoSave: setting.autoSave ?? false)
            return s
        }
    }
    
    private func updateIncrease(setting: SettingFont) -> SettingFont? {
        guard let index = SizeFont.allCases.firstIndex(of: setting.size) else { return nil}
    
        switch setting.size {
        case .onehundredThirty:
            let imgPlus = Asset.icPlusInactive.image
            self.btIncreaseFont.setImage(imgPlus, for: .normal)
            return nil
        default:
            let s = SettingFont(size: SizeFont.allCases[index + 1], name: setting.name, isEnableButton: setting.isEnableButton, autoSave: setting.autoSave ?? false)
            return s
        }
    }
    
    private func updateUIFont(setting: SettingFont) {
        self.settingFont = setting
        self.lbValueFont.text = setting.show
        switch setting.name {
        case .hiraginoSansW4:
            self.btHiraginoSans.setTitleColor(Asset.textFontSelect.color, for: .normal)
            self.btHiraginoSans.backgroundColor = Asset.cc3333.color
            self.btHiraginoSans.layer.borderColor = Asset.cc3333.color.cgColor
//            self.lbHiraginoSans.textColor = Asset.highlight.color
            self.btHiraginoMincho.setTitleColor(Asset.textFontUnselect.color, for: .normal)
            self.btHiraginoMincho.backgroundColor = .white
            self.btHiraginoMincho.layer.borderColor = Asset.cececeFfffff.color.cgColor
//            self.lbHiraginoMincho.textColor = Asset.textGreyDisable.color
            
        case .hiraginoMinchoW3:
            self.btHiraginoSans.setTitleColor(Asset.textFontUnselect.color, for: .normal)
            self.btHiraginoSans.backgroundColor = .white
            self.btHiraginoSans.layer.borderColor = Asset.cececeFfffff.color.cgColor
//            self.lbHiraginoSans.textColor = Asset.textGreyDisable.color
            self.btHiraginoMincho.setTitleColor(Asset.textFontSelect.color, for: .normal)
            self.btHiraginoMincho.backgroundColor = Asset.cc3333.color
            self.btHiraginoMincho.layer.borderColor = Asset.cc3333.color.cgColor
//            self.lbHiraginoMincho.textColor = Asset.highlight.color
        }
    }
    
    func updateUI(state: SettingViewController.StateCell, settingFont: SettingFont) {
        self.updateUIFont(setting: settingFont)
        
        
        let vButton = [self.btIncreaseFont, self.btDecreaseFont]
        
        vButton.forEach { (b) in
            if settingFont.isEnableButton {
                b?.isEnabled = true
                b?.layer.borderColor = UIColor.black.cgColor
                let imgPlus = Asset.icMinusActive.image
                self.btDecreaseFont.setImage(imgPlus, for: .normal)
                let imgMinus = Asset.icPlusActive.image
                self.btIncreaseFont.setImage(imgMinus, for: .normal)
//                self.lbPlus.textColor = .black
//                self.lbMinus.textColor = .black

            } else {
                b?.isEnabled = false
                b?.layer.borderColor = UIColor.darkGray.cgColor
                let imgPlus = Asset.icMinusInactive.image
                self.btDecreaseFont.setImage(imgPlus, for: .normal)
                let imgMinus = Asset.icPlusInactive.image
                self.btIncreaseFont.setImage(imgMinus, for: .normal)
//                self.lbPlus.textColor = .darkGray
//                self.lbMinus.textColor = .darkGray
            }
            
        }
        
        switch state {
        case .font:
            self.vFont.isHidden = false
            
            self.vShare.isHidden = true
            self.vFontSize.isHidden = true
            self.autoSaveView.isHidden = true
            
        case .fontSize:
            self.vFontSize.isHidden = false
            
            self.vShare.isHidden = true
            self.vFont.isHidden = true
            self.autoSaveView.isHidden = true
            
        case .share:
            self.vShare.isHidden = false
            
            self.vFontSize.isHidden = true
            self.vFont.isHidden = true
            self.autoSaveView.isHidden = true
        case .autoSave:
            self.autoSaveView.isHidden = false
            
            self.vShare.isHidden = true
            self.vFontSize.isHidden = true
            self.vFont.isHidden = true
        }
        
        switch settingFont.size {
        case .eighty:
            let imgPlus = Asset.icMinusInactive.image
            self.btDecreaseFont.setImage(imgPlus, for: .normal)
            
        case .onehundredThirty:
            let imgPlus = Asset.icPlusInactive.image
            self.btIncreaseFont.setImage(imgPlus, for: .normal)
        
        default:
            let imgPlus = Asset.icMinusActive.image
            self.btDecreaseFont.setImage(imgPlus, for: .normal)
            let imgMinus = Asset.icPlusActive.image
            self.btIncreaseFont.setImage(imgMinus, for: .normal)
        }
        
        self.autoSaveSwitch.isOn = settingFont.autoSave ?? false
    }
}
