//
//  SettingSearchCell.swift
//  GooDic
//
//  Created by paxcreation on 5/24/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

class SettingSearchCell: UITableViewCell {
    
    struct Constant {
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowOpacity: Float = 1
    }

    @IBOutlet weak var vSearch: UIView!
    @IBOutlet weak var vReplace: UIView!
    @IBOutlet weak var vPay: UIView!
    @IBOutlet weak var btSearch: UIButton!
    @IBOutlet weak var btReplace: UIButton!
    @IBOutlet weak var vContentPay: UIView!
    @IBOutlet weak var lbReplace: UILabel!
    @IBOutlet weak var imgPreniumGray: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        
//         Shadow Color and Radius
        self.vContentPay.clipsToBounds = true
        self.vContentPay.layer.borderWidth = 1
        self.vContentPay.layer.cornerRadius = 7
        self.vContentPay.layer.borderColor = Asset.cc3333.color.cgColor
        self.vContentPay.layer.shadowColor = Asset.cecece464646.color.cgColor
        self.vContentPay.layer.shadowOffset = Constant.shadowOffset
        self.vContentPay.layer.shadowOpacity = Constant.shadowOpacity
//        self.vContentPay.layer.shadowRadius = 2
        self.vContentPay.layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.updateLabelReplace()
    }
    
}
extension SettingSearchCell {
    
    func updateUI(state: SettingSearchViewController.StateCell, setting: SettingSearch) {
        
        self.imgPreniumGray.isHidden = (AppSettings.settingSearch?.billingStatus == .paid) ? true : false
        
        switch state {
        case .search:
            self.vSearch.isHidden = false
            self.btSearch.isHidden = !setting.isSearch
            
            let v = [self.vReplace, vPay]
            v.forEach { (v) in
                v?.isHidden = true
            }
            
        case .replace:
            self.vReplace.isHidden = false
            self.btReplace.isHidden = !setting.isReplace
            
            self.updateLabelReplace()
            
            let v = [self.vSearch, vPay]
            self.hideView(vs: v)
        case .pay:
            self.vPay.isHidden = false
            
            let v = [self.vSearch, self.vReplace]
            self.hideView(vs: v)
        }
    }
    
    private func updateLabelReplace() {
        if AppSettings.settingSearch?.billingStatus == .free {
            self.lbReplace.textColor = Asset.cecece717171.color
        } else {
            self.lbReplace.textColor = Asset._111111Ffffff.color
        }
        
        self.vContentPay.layer.borderColor = Asset.cc3333.color.cgColor
        self.vContentPay.layer.shadowColor = Asset.cecece464646.color.cgColor
    }
    
    private func hideView(vs: [UIView?]) {
        vs.forEach { (v) in
            v?.isHidden = true
        }
    }
}
