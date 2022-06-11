//
//  DocumentTVC.swift
//  GooDic
//
//  Created by ttvu on 5/27/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class DocumentTVC: UITableViewCell, ReusableView {

    struct Constant {
        static let cellHeight: CGFloat = 90.0
        static let titleFont = UIFont.hiraginoSansW6(size: 16)
        static let dataColor = Asset.textPrimary.color
        static let noTitleFont = UIFont.hiraginoSansW3(size: 16)
        static let noDataColor = Asset.noData.color
        static let noTitleText = L10n.Home.Cell.noTitle
        static let noContentText = L10n.Home.Cell.noContent
    }
    
    var isManual: Bool = false
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var folderPlaceholder: UIView!
    @IBOutlet weak var folderNameLabel: UILabel!
    @IBOutlet weak var folderIcon: UIImageView!
    
    private var titleString: String?
    private var contentString: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        multipleSelectionBackgroundView = UIView()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        
        if editing && self.isManual {
            self.setupViewSort()
        } else {
            self.removeReorderView()
        }
    }

    func bind(title: String, content: String, date: String, folderName: String? = nil, onCloud: Bool = false) {
        var lessText: String
        
        if content.count <= AppManager.shared.detectBodyDraftGreaterThan100 {
            lessText = content
        } else {
            lessText = String(content.prefix(AppManager.shared.detectBodyDraftGreaterThan100))
        }
        
        self.dateLabel.text = date
        
        self.titleLabel.text = title.isEmpty ? Constant.noTitleText : title
        titleString = title
        self.contentLabel.text = lessText.isEmpty ? Constant.noContentText : lessText
        contentLabel.layoutIfNeeded()
        contentString = lessText
        if contentLabel.maxNumberOfLines > 1 {
            if let firstLine = contentLabel.getLinesArrayOfString()?.first {
                self.contentLabel.text = firstLine.trimmingCharacters(in: CharacterSet.newlines) + "⋯"
            }
        }
        self.folderNameLabel.text = folderName
        if let folderName = folderName, !folderName.isEmpty {
            folderPlaceholder.isHidden = false
            self.folderNameLabel.text = folderName
            self.folderIcon.image = onCloud ? Asset.icCloudFolder.image : Asset.icLocalFolder.image
        } else {
            folderPlaceholder.isHidden = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if titleString?.isEmpty ?? true {
            self.titleLabel.textColor = Constant.noDataColor
            self.titleLabel.font = Constant.noTitleFont
        } else {
            self.titleLabel.textColor = Constant.dataColor
            self.titleLabel.font = Constant.titleFont
        }
        
        if contentString?.isEmpty ?? true {
            self.contentLabel.textColor = Constant.noDataColor
        } else {
            self.contentLabel.textColor = Constant.dataColor
        }
        self.backgroundColor = Asset.ffffff121212.color
        self.alpha = 1
        self.setupViewSort()
        setSelected(self.isSelected, animated: false)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            multipleSelectionBackgroundView?.backgroundColor = Asset.seletedRow.color
            setCheckMarkImageView(image: Asset.icRadioRedOn.image)
        } else {
            multipleSelectionBackgroundView?.backgroundColor = Asset.normalRow.color
            setCheckMarkImageView(image: Asset.icRadioRedOff.image)
        }
    }
    
    override func didTransition(to state: UITableViewCell.StateMask) {
        if state == .showingEditControl {
            setCheckMarkImageView(image: Asset.icRadioRedOff.image)
        }
    }
    
    func removeReorderView() {
        for view in subviews where view.description.contains("Reorder") {
            DispatchQueue.main.async(execute: {
                view.removeFromSuperview()
                self.layoutIfNeeded()
            })
        }
    }
    
    func setupViewSort() {
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
                view.heightAnchor.constraint(equalToConstant: Constant.cellHeight),
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
}
