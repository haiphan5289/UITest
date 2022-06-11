//
//  MenuItemPremiumLimitedCell.swift
//  GooDic
//
//  Created by Vinh Nguyen on 11/02/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit

class MenuItemPremiumLimitedCell: UITableViewCell, ReusableView {
    
    @IBOutlet weak var stArrowImageView: UIImageView!
    @IBOutlet weak var stTitle: UILabel!
    @IBOutlet weak var stFreeForFistTimeTitle: UILabel!
    
    @IBOutlet weak var stPCTitle: UILabel!
    @IBOutlet weak var stAdsTitle: UILabel!
    @IBOutlet weak var stDetailSearchTitle: UILabel!
    @IBOutlet weak var stReplaceFunctionTitle: UILabel!
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var freeForFistTimeView: UIView!
    @IBOutlet weak var stSeparatorView: UIView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(data: MenuData) {
        stTitle.text = data.title
    }
    
    func setupUI() {
        self.stPCTitle.text = L10n.Menu.Cell.Item.pc
        self.stAdsTitle.text = L10n.Menu.Cell.Item.noAds
        self.stDetailSearchTitle.text = L10n.Menu.Cell.Item.detailedSearch
        self.stReplaceFunctionTitle.text = L10n.Menu.Cell.Item.replaceFunction
        self.stFreeForFistTimeTitle.text = L10n.Menu.Cell.Item.oneMonthFreeFirstTime

        stArrowImageView.image = Asset.icArrowRed.image
        mainView.layer.borderWidth = 1
        mainView.layer.cornerRadius = 8
        mainView.layer.masksToBounds = true
        mainView.layer.borderColor = Asset.ec8383.color.cgColor
        stSeparatorView.backgroundColor = Asset.cellSeparator.color
        

        freeForFistTimeView.layer.cornerRadius = 8
        freeForFistTimeView.layer.masksToBounds = true
        freeForFistTimeView.backgroundColor =  Asset.ec8383.color
    }
}
