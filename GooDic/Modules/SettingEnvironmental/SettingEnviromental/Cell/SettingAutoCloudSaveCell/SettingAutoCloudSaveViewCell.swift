//
//  SettingAutoCloudSaveViewCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

class SettingAutoCloudSaveViewCell: UITableViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var contentLbl: UILabel!
    
    @IBOutlet weak var autoSaveSwitch: UISwitch!
    
    var showAlertAutoSave: ((Bool) -> Void)?
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        self.setupRX()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(data: SettingEnviromentalData) {
        self.titleLbl.text = data.title
        self.autoSaveSwitch.isOn = AppSettings.settingFont?.autoSave ?? false
    }
    
    private func changeValueSetting(setting: SettingFont) {
        AppSettings.settingFont = setting
    }
    
    private func setupUI() {
        self.autoSaveSwitch.clipsToBounds = true
        self.autoSaveSwitch.layer.cornerRadius = self.autoSaveSwitch.frame.height / 2
        
        self.contentLbl.text = L10n.SettingEnviromental.AutoCloudSaveCell.content
    }
    
    private func setupRX() {
        self.autoSaveSwitch.rx.controlEvent(.valueChanged).bind { [weak self] _ in
            guard let wSelf = self, let settting = AppSettings.settingFont else { return }
   
            let s = SettingFont(size: settting.size, name: settting.name, isEnableButton: settting.isEnableButton, autoSave: wSelf.autoSaveSwitch.isOn)
            wSelf.changeValueSetting(setting: s)
            wSelf.showAlertAutoSave?(wSelf.autoSaveSwitch.isOn)
        }.disposed(by: disposeBag)
    }
    
}
