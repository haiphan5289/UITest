//
//  BackupListViewCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 26/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

class BackupListViewCell: UITableViewCell {
    
    @IBOutlet weak var stArrowImageView: UIImageView!
    @IBOutlet weak var stTitle: UILabel!
    @IBOutlet weak var stContent: UILabel!
    
    @IBOutlet weak var lineBottomView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(data: CloudBackupDocument) {
        self.stTitle.text = data.title
        self.stContent.text = data.content
    }
    
}
