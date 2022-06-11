//
//  SettingBackupMinuteViewCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

class SettingBackupMinuteViewCell: UITableViewCell {
    
    @IBOutlet weak var stCheckImageView: UIImageView!
    @IBOutlet weak var stTitle: UILabel!
    
    @IBOutlet weak var lineBottomView: UIView!
    var settingBackupMinute: SettingBackupMinute = .zero
    private let isBilling = AppManager.shared.billingInfo.value.billingStatus == .free ? false : true

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(data: SettingBackupData) {
        stTitle.text = data.title + L10n.SettingBackup.minute
        settingBackupMinute = SettingBackupMinute.getElement(text: data.title)
    }
    
    
    func updateCheckMinute() {
        if AppSettings.settingBackupModel.isPeriodicBackup == false {
            self.stCheckImageView.isHidden = true
        } else {
            if settingBackupMinute == SettingBackupMinute.zero {
                self.stCheckImageView.isHidden = true
            } else {
                self.stCheckImageView.isHidden = !(AppSettings.settingBackupModel.interval == settingBackupMinute.integer)
            }
        }
    }
    
    func updateCellWithBilling () {
        if isBilling {
            self.stTitle.textColor = (AppSettings.settingBackupModel.isPeriodicBackup ?? false) ? Asset._111111Ffffff.color : Asset.cecece555555.color
            self.updateCheckMinute()
        } else {
            self.stTitle.textColor = Asset.cecece555555.color
            self.stCheckImageView.isHidden =  true
        }
    }
    
}
