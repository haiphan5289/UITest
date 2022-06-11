//
//  FolderSortCell.swift
//  GooDic
//
//  Created by haiphan on 10/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

class FolderSortCell: UITableViewCell, ReusableView {

    @IBOutlet weak var img: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSort(sortModel: SortModel) {
        switch  sortModel.sortName {
        case .created_at, .updated_at:
            let img = (sortModel.asc) ? Asset.imgCreatedateAscending.image : Asset.imgCreatedateDescending.image
            self.img.image = img
        case .title:
            let img = (sortModel.asc) ? Asset.imgTittleAscending.image : Asset.imgTittleDescending.image
            self.img.image = img
        case .manual:
            let img = ((sortModel.isActiveManual ?? false)) ? Asset.icArrowAscending.image : Asset.icArrowDescending.image
            self.img.image = img
        case .free: break
        }
    }
}
