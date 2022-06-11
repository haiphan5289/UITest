//
//  TagView.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

protocol TagViewDelegate: class {
    func tagView(_ tagView: TagView, didSelectAt button: TagButton)
}

enum TagType: Equatable {
    case main(String, String) // name, id
    case arrow
    case suggestion(String, String, Bool) // name, id, isSelected
}

class TagView: UIView {
    
    struct Constant {
        static var vPadding: CGFloat = 10
        static var hArrowPadding: CGFloat = 2
        static var hPadding: CGFloat = 8
    }
    
    private var tags: [TagType] = []
    
    private var expectedSize: CGSize = CGSize(width: 10, height: 10) {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    weak var delegate: TagViewDelegate?
    var builder = TagBuilder()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = layoutTags(withWidth: self.bounds.width)
        
        self.expectedSize = CGSize(width: self.bounds.size.width, height: height)
    }
    
    override var intrinsicContentSize: CGSize {
        return expectedSize
    }
    
    func setTags(tags: [TagType]) {
        self.tags = tags
        
        subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        
        tags.forEach { (tagType) in
            let tag = builder.createTag(tagType: tagType)
            self.addSubview(tag)
            
            if let tagButton = tag as? TagButton {
                tagButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            }
            
        }
    }
    
    func appendTag(tag: TagType) {
        self.tags.append(tag)
        
        let tag = builder.createTag(tagType: tag)
        self.addSubview(tag)
        
        if let tagButton = tag as? TagButton {
            tagButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
    }
    
    @objc func buttonPressed(_ button: TagButton) {
        delegate?.tagView(self, didSelectAt: button)
    }
    
    @discardableResult
    private func layoutTags(withWidth width: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lastY: CGFloat = 0
        var lastTag: TagType?
        subviews.forEach { (subView) in
            var hPadding = Constant.hPadding
            
            if let button = subView as? TagButton {
                button.fitSize(maxWidth: width)
                
                if button.tagType == TagType.arrow || lastTag == TagType.arrow {
                    hPadding = Constant.hArrowPadding
                }
                
                lastTag = button.tagType
            }
            
            if subView.bounds.width >= width - x {
                // line break
                x = 0
                y = lastY + Constant.vPadding
            }
            
            subView.frame.origin.x = x
            subView.frame.origin.y = y
            lastY = subView.frame.maxY
            x = subView.frame.maxX + hPadding
        }
        
        return lastY
    }
    
    func expectedHeight(withWidth width: CGFloat) -> CGFloat {
        return layoutTags(withWidth: width) + 2 * Constant.vPadding
    }
    
    class func expectedHeight(withWidth width: CGFloat, tags: [TagType]) -> CGFloat {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lastY: CGFloat = 0
        var lastTag: TagType?
        
        tags.forEach { (tag) in
            var hPadding = Constant.hPadding
            var tagFrame = CGRect(origin: .zero, size: .zero)
            switch tag {
            case let .main(name, _):
                tagFrame.size = TagButton.estimateSize(maxWidth: width,
                                              text: name,
                                              font: TagBuilder.Constant.font,
                                              horizontalGap: TagBuilder.Constant.mainTagHorizontalGap,
                                              minHeight: TagBuilder.Constant.minHeight)
                
            case .arrow:
                tagFrame.size = CGSize(width: 22, height: 22)
            case let .suggestion(name, _, _):
                tagFrame.size = TagButton.estimateSize(maxWidth: width,
                                              text: name,
                                              font: TagBuilder.Constant.font,
                                              horizontalGap: TagBuilder.Constant.suggestionTagHorizontalGap,
                                              minHeight: TagBuilder.Constant.minHeight)
            }
            
            if tag == TagType.arrow || lastTag == TagType.arrow {
                hPadding = Constant.hArrowPadding
            }
            lastTag = tag
            
            if tagFrame.width >= width - x {
                // line break
                x = 0
                y = lastY + Constant.vPadding
            }
            
            tagFrame.origin.x = x
            tagFrame.origin.y = y
            lastY = tagFrame.maxY
            x = tagFrame.maxX + hPadding
        }
        
        return lastY + 2 * Constant.vPadding
    }
}
