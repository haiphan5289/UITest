//
//  SuggestionTVC.swift
//  GooDic
//
//  Created by ttvu on 5/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class SuggestionTVC: UITableViewCell, ReusableView {

    struct Constant {
        // base on Storyboard
        static let leftConstraint: CGFloat = 50.0
        // base on Storyboard
        static let rightConstraint: CGFloat = 10.0
    }
    
    // MARK: - UI
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var tagView: TagView!
    
    // MARK: - Data
    var detailUrlPath: String?
    
    var tappedOnInfoBlock: ((String?)->Void)?
    var tappedOnTagBlock: ((TagType)->Void)?
    
    // MARK: - Life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tappedOnTagBlock = nil
        tappedOnInfoBlock = nil
        tagView.delegate = self
    }

    // MARK: - Funcs
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        if let path = detailUrlPath {
            tappedOnInfoBlock?(path)
        }
    }
    
    func bind(data: GDDataItem) {
        self.detailUrlPath = data.detailUrlPath
        tagView.setTags(tags: data.tags())
        tagView.delegate = self
    }
    
    class func tagViewWidth(withTableViewWidth width: CGFloat) -> CGFloat {
        // you need to update the following value after updating Nib
        let tagViewWidth = width - Constant.leftConstraint - Constant.rightConstraint
        
        return tagViewWidth
    }
}

extension SuggestionTVC: TagViewDelegate {
    func tagView(_ tagView: TagView, didSelectAt button: TagButton) {
        self.tappedOnTagBlock?(button.tagType)
    }
}

extension GDDataItem {
    func tags() -> [TagType] {
        let targetTag = TagType.main(name, id)
        let suggestionTags = suggestions.map({ TagType.suggestion($0.name, $0.id, $0.isSelected)})
        return [targetTag, TagType.arrow] + suggestionTags
    }
}
