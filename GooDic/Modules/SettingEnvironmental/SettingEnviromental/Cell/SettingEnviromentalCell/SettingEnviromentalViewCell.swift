//
//  SettingEnviromentalViewCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

class SettingEnviromentalViewCell: UITableViewCell {
    
    @IBOutlet weak var stArrowImageView: UIImageView!
    @IBOutlet weak var stTitle: UILabel!
    
    @IBOutlet weak var onLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.onLbl.text = L10n.SettingEnviromental.BackupCell.on
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(data: SettingEnviromentalData) {
        stTitle.text = data.title
    }
    
}
