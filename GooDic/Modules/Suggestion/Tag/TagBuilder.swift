//
//  TagBuilder.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

struct TagBuilder {
    
    struct Constant {
        static let minHeight: CGFloat = 30
        static let font = UIFont.hiraginoSansW4(size: 13)
        static let mainTagHorizontalGap: CGFloat = 9
        static let suggestionTagHorizontalGap: CGFloat = 20
    }
    
    var minHeight: CGFloat { Constant.minHeight }
    var font: UIFont { Constant.font }
    
    func createTag(tagType: TagType) -> UIView {
        switch tagType {
        case.arrow:
            return createArrowTag()
        case .main(_, _), .suggestion(_, _, _):
            return createButtonTag(tagType)
        }
    }
    
    func createButtonTag(_ tag: TagType) -> UIButton {
        let button = TagButton()
        button.tagType = tag
        
        return button
    }
    
    func createArrowTag() -> UIImageView {
        let image = Asset.imgShouldBe.image
        let imageView = UIImageView(image: image)

        imageView.contentMode = .scaleAspectFill
        imageView.bounds = CGRect(x: 0, y: 0, width: imageView.bounds.width, height: minHeight)
        return imageView
    }
}
