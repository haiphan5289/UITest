//
//  SettingBackupViewCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

class SettingBackupViewCell: UITableViewCell {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var contentLbl: UILabel!
    @IBOutlet weak var lineBottomView: UIView!
    @IBOutlet weak var itemSwitch: UISwitch!
    
    var actionSwitch: ((SettingBackupModel) -> Void)?
    var showAlertEnableBackup: ((Bool) -> Void)?
    private let disposeBag = DisposeBag()
    private var action = SettingBackupAction.none
    private let isLogin = AppManager.shared.userInfo.value != nil
    private let isBilling = AppManager.shared.billingInfo.value.billingStatus == .free ? false : true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupRX()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setupRX() {
        self.itemSwitch.rx.controlEvent(.valueChanged).bind { [weak self] _ in
            guard let wSelf = self else { return }
            
            switch wSelf.action {
            case .isBackup:
                if AppSettings.firstEnableSettingBackup == true {
                    AppSettings.firstEnableSettingBackup = false
                    let setttingBackup = SettingBackupModel(
                        isBackup: wSelf.itemSwitch.isOn,
                        isManualSaveBackup: true,
                        isPeriodicBackup: true,
                        interval: SettingBackupMinute.ten.integer)
                    wSelf.actionSwitch?(setttingBackup)
                } else {
                    let setttingBackup = SettingBackupModel(
                        isBackup: wSelf.itemSwitch.isOn,
                        isManualSaveBackup: AppSettings.settingBackupModel.isManualSaveBackup ?? false,
                        isPeriodicBackup: AppSettings.settingBackupModel.isPeriodicBackup ?? false,
                        interval: AppSettings.settingBackupModel.interval ?? SettingBackupMinute.zero.integer)
                    wSelf.actionSwitch?(setttingBackup)
                }
                wSelf.showAlertEnableBackup?(wSelf.itemSwitch.isOn)
                break
            case .isManualSaveBackup:
                let setttingBackup = SettingBackupModel(
                    isBackup: AppSettings.settingBackupModel.isBackup ?? true,
                    isManualSaveBackup: wSelf.itemSwitch.isOn,
                    isPeriodicBackup: AppSettings.settingBackupModel.isPeriodicBackup ?? false,
                    interval: AppSettings.settingBackupModel.interval ?? SettingBackupMinute.zero.integer)
                wSelf.actionSwitch?(setttingBackup)
                break
            case .isPeriodicBackup:
                let setttingBackup = SettingBackupModel(
                    isBackup: AppSettings.settingBackupModel.isBackup ?? true,
                    isManualSaveBackup: AppSettings.settingBackupModel.isManualSaveBackup ?? false,
                    isPeriodicBackup: wSelf.itemSwitch.isOn,
                    interval: AppSettings.settingBackupModel.interval ?? SettingBackupMinute.zero.integer)
                wSelf.actionSwitch?(setttingBackup)
                break
            case .isSelectMinute:
                break
            case .none:
                break
            }
        }.disposed(by: disposeBag)
    }
    
    func bind(data: SettingBackupData) {
        titleLbl.text = data.title
        contentLbl.text = data.content
        action = data.action
    }
    
    func setHiddenLineBottomView(isHidden: Bool) {
        self.lineBottomView.isHidden = isHidden
    }
    
    func updateCellWithStatusBackup() {
        self.itemSwitch.isOn = isBilling ? (AppSettings.settingBackupModel.isBackup ?? false) : false
        self.itemSwitch.isEnabled = isBilling ? true : false
    }
    
    func updateCellWithBilling () {
        if isBilling {
            self.titleLbl.textColor = (AppSettings.settingBackupModel.isBackup ?? false) ? Asset._111111Ffffff.color : Asset.cecece555555.color
            
            self.contentLbl.textColor = (AppSettings.settingBackupModel.isBackup ?? false) ? Asset._666666Cfcfcf.color : Asset.cecece555555.color
            self.itemSwitch.isEnabled =  (AppSettings.settingBackupModel.isBackup ?? false) ? true : false
            switch self.action {
                case .isBackup:
                    self.itemSwitch.isOn = isBilling ? (AppSettings.settingBackupModel.isBackup ?? false) : false
                    break
                case .isManualSaveBackup:
                    self.itemSwitch.isOn = (AppSettings.settingBackupModel.isBackup ?? false) ?  (AppSettings.settingBackupModel.isManualSaveBackup ?? false) : false
                    break
                case .isPeriodicBackup:
                    self.itemSwitch.isOn = (AppSettings.settingBackupModel.isBackup ?? false) ? (AppSettings.settingBackupModel.isPeriodicBackup ?? false) : false
                    break
                case .isSelectMinute: break
                case .none: break
            }
        } else {
            self.titleLbl.textColor =  Asset.cecece555555.color
            self.contentLbl.textColor =  Asset.cecece555555.color
            self.itemSwitch.isEnabled = false
            self.itemSwitch.isOn = false
        }
    }
}
