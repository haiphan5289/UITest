//
//  FolderTVC.swift
//  GooDic
//
//  Created by ttvu on 9/14/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

enum SelectionType {
    case none
    case selected
    case unselected
}

class FolderTVC: UITableViewCell, ReusableView {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
//    @IBOutlet weak var numOfDraftsLbl: UILabel!
    
    private var canInteraction: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if editing {
            self.setupViewSort()
        }
    }
    
    private func setupViewSort() {
        for view in subviews where view.description.contains("Reorder") {
            for case let subview as UIImageView in view.subviews {
                var f = view.frame
                f.size = CGSize(width: 24, height: 24)
                subview.frame = f
                subview.image = Asset.icSort.image
                
            }
        
            let margins = self
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.rightAnchor.constraint(equalTo: margins.rightAnchor, constant: 0),
                view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                view.topAnchor.constraint(equalTo: margins.topAnchor, constant: 0),
                view.heightAnchor.constraint(equalToConstant: 48.5),
                view.widthAnchor.constraint(equalToConstant: 48.5)
            ])
            
            view.clipsToBounds = true
            
            let lineView: UIView = UIView(frame: .zero)
            lineView.backgroundColor = Asset.cellSeparator.color
            
            view.addSubview(lineView)
            lineView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                lineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                lineView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                lineView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                lineView.widthAnchor.constraint(equalToConstant: 0.5)
            ])
            
            self.layoutIfNeeded()
        }
    }
    
    func bind(name: String, iconImage: UIImage = Asset.icLocalFolder.image, type: SelectionType = .none, canInteraction: Bool = true) {
        titleLbl.text = name
        self.icon.image = iconImage
        self.canInteraction = canInteraction
        
        switch type {
        case .none:
//            numOfDraftsLbl.text = ""//"\(data.documents.count)"
            break
        case .selected:
//            numOfDraftsLbl.text = ""
            accessoryType = .checkmark
        case .unselected:
//            numOfDraftsLbl.text = ""
            accessoryType = .none
        }
    }
    
    func bind(data: Folder, iconImage: UIImage = Asset.icLocalFolder.image, type: SelectionType = .none, canInteraction: Bool = true) {
        titleLbl.text = data.name
        self.icon.image = iconImage
        self.canInteraction = canInteraction
        
        switch type {
        case .none:
//            numOfDraftsLbl.text = ""//"\(data.documents.count)"
            break
        case .selected:
//            numOfDraftsLbl.text = ""
            accessoryType = .checkmark
        case .unselected:
//            numOfDraftsLbl.text = ""
            accessoryType = .none
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if canInteraction {
            titleLbl.textColor = Asset.textPrimary.color
            self.selectionStyle = .default
        } else {
            titleLbl.textColor = Asset.textGreyDisable.color
            self.selectionStyle = .none
        }
        self.backgroundColor = Asset.ffffff121212.color
        self.alpha = 1
        self.setupViewSort()
    }
}
