//
//  DropDownTVC.swift
//  GooDic
//
//  Created by ttvu on 9/8/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class DropDownTVC: UITableViewCell, ReusableView {
    
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(data: String) {
        title.text = data
    }
    
    func showLineView() {
        self.lineView.isHidden = false
    }
}
