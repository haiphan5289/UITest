//
//  MenuTableViewCell.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell, ReusableView {

    @IBOutlet weak var stImageView: UIImageView!
    @IBOutlet weak var stArrowImageView: UIImageView!
    @IBOutlet weak var stTitle: UILabel!
    @IBOutlet weak var minHeightTitle: NSLayoutConstraint!
    @IBOutlet weak var leftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var stSeparatorView: UIView!
    @IBOutlet weak var leftPaddingImageViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightPaddingArrowConstraint: NSLayoutConstraint!
    
    var sceneType: GATracking.Scene = .appPolicy
    
    func bind(data: MenuData) {
        stTitle.text = data.title
        stImageView.image = data.icon
        stTitle.textColor = data.sceneType == .requestPremium ? Asset.textFontUnselect.color : Asset.textPrimary.color
        leftPaddingConstraint.constant = data.sceneType == .requestPremium ? 10 : 0
        rightPaddingConstraint.constant = data.sceneType == .requestPremium ? 10 : 0
        bottomPaddingConstraint.constant = data.sceneType == .requestPremium ? 10 : 0
        leftPaddingImageViewConstraint.constant = data.sceneType == .requestPremium ? 10 : 20
        rightPaddingArrowConstraint.constant = data.sceneType == .requestPremium ? 6 : 8
        minHeightTitle.constant = data.sceneType == .requestPremium ? 40 : 30
        mainView.layer.borderWidth = data.sceneType == .requestPremium ? 1 : 0
        mainView.layer.cornerRadius = data.sceneType == .requestPremium ? 8 : 0
        mainView.layer.masksToBounds = true
        mainView.layer.borderColor = Asset.highlight.color.cgColor
        mainView.backgroundColor = data.sceneType == .requestPremium ? Asset.normalRow.color : Asset.background.color
        stSeparatorView.backgroundColor = Asset.cellSeparator.color
        
        // cosmetics
        mainView.layer.masksToBounds = false
        mainView.layer.shadowRadius = 0
        mainView.layer.shadowOpacity = 1
        mainView.layer.shadowColor = data.sceneType == .requestPremium
            ? Asset.naviBarShadow.color.cgColor
            : UIColor.clear.cgColor
        mainView.layer.shadowOffset = CGSize(width: 0, height: 1)
        sceneType = data.sceneType
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        mainView.layer.shadowColor = sceneType == .requestPremium
            ? Asset.naviBarShadow.color.cgColor
            : UIColor.clear.cgColor
    }
}
