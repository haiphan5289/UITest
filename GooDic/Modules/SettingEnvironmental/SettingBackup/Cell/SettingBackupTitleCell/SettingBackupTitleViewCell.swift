//
//  SettingBackupTitleViewCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

class SettingBackupTitleViewCell: UITableViewCell {

    @IBOutlet weak var contentSubView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    
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
        titleLbl.text = data.title
    }
    
    func updateCellWithBilling () {
        if isBilling {
            self.titleLbl.textColor = (AppSettings.settingBackupModel.isBackup ?? false) ? Asset._000000Ffffff.color : Asset.d6D6D6555555.color
        } else {
            self.titleLbl.textColor = Asset.d6D6D6555555.color
        }
    }
    
}
