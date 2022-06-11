//
//  TagButton.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class TagButton: UIButton {
    
    struct Constant {
        static let minHeight: CGFloat = 30
        static let font = UIFont.hiraginoSansW4(size: 13)
        static let mainTagHorizontalGap: CGFloat = 9
        static let suggestionTagHorizontalGap: CGFloat = 20
    }
    
    var tagType: TagType = .arrow {
        didSet {
            setupUI()
        }
    }
    
    private func setupUI() {
        switch tagType {
        case .main(let title, _):
            self.setTitle(title, for: .normal)
            
            self.backgroundColor = Asset.suggestionButtonBg.color
            self.setTitleColor(UIColor.black, for: .normal)
            
            self.titleLabel?.font = Constant.font
            self.titleLabel?.lineBreakMode = .byWordWrapping
            self.titleLabel?.numberOfLines = 0
            
            let gap = (Constant.minHeight - Constant.font.lineHeight) / 2
            let horizontalGap: CGFloat = Constant.mainTagHorizontalGap
            self.contentEdgeInsets = UIEdgeInsets(top: gap, left: horizontalGap, bottom: gap, right: horizontalGap)
            
        case let .suggestion(title, _, isSelected):
            var image: UIImage = Asset.icChanged.image
            
            self.setTitle(title, for: .normal)
                
            if isSelected == false {
                image = UIImage.fromView(UIView(frame: CGRect(origin: .zero, size: image.size)))
            }
            
            self.imageView?.contentMode = .scaleAspectFill
            self.setImage(image, for: .normal)
            self.semanticContentAttribute = .forceRightToLeft
            
            self.backgroundColor = Asset.suggestionTagBg.color
            self.setTitleColor(Asset.highlight.color, for: .normal)
            
            self.titleLabel?.font = Constant.font
            self.titleLabel?.lineBreakMode = .byWordWrapping
            self.titleLabel?.numberOfLines = 0
            
            self.layer.borderWidth = 2
            self.layer.borderColor = Asset.suggestionTagBorder.color.cgColor
            
            let gap = (Constant.minHeight - Constant.font.lineHeight) / 2
            
            let leftGap: CGFloat = Constant.suggestionTagHorizontalGap
            let rightGap: CGFloat = leftGap - image.size.width // to make sure that the tag's size isn't changed
            self.contentEdgeInsets = UIEdgeInsets(top: gap, left: leftGap, bottom: gap, right: rightGap)
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0) // params are set based on the image's size
            
        default:
            break
        }
    }
    
    func fitSize(maxWidth: CGFloat) {
        guard let titleLabel = titleLabel else { return }
        var imageSize: CGSize = .zero
        if let image = self.image(for: .normal) {
            imageSize = image.size
        }
        let gaps = contentEdgeInsets.left + contentEdgeInsets.right + imageSize.width
        let maxSize = CGSize(width: maxWidth - gaps,
                             height: CGFloat.infinity)
        var size = titleLabel.sizeThatFits(maxSize)
        size.height = size.height < titleLabel.font.pointSize ? titleLabel.font.pointSize : size.height
        bounds = CGRect(x: 0,
                        y: 0,
                        width: size.width + gaps,
                        height: size.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
    }
    
    /// estimate button's size
    /// NOTE: in my case, I ignored imageSize. Please be careful while using this function in the future
    class func estimateSize(maxWidth: CGFloat, text: String, font: UIFont, horizontalGap: CGFloat, minHeight: CGFloat) -> CGSize {
        var verticalGap = (minHeight - font.pointSize) / 2
        if verticalGap < 0 {
            verticalGap = 0
        }
        
        let textSize = text.expectedSize(withWidth: maxWidth - horizontalGap * 2, font: font)
        
        return CGSize(width: textSize.width + horizontalGap * 2,
                      height: textSize.height + verticalGap * 2)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *), self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if case .suggestion(_, _, _) = tagType {
                self.layer.borderColor = Asset.suggestionTagBorder.color.cgColor
            }
        }
    }
}

extension TagButton: CapsuleProtocol {
    
    convenience init() {
        self.init(type: .custom)
        
        makeCapsule()
    }
    
    var cornerRadius: CGFloat {
        return 15.0
    }
}
