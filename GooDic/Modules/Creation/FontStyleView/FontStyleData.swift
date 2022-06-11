//
//  FontStyleData.swift
//  GooDic
//
//  Created by ttvu on 9/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

struct FontStyleData: Codable {
    var id: Int = 0
    let titleFontName: String
    let titleFontSize: CGFloat
    let titleLineHeight: CGFloat
    let titleKern: CGFloat
    let contentFontName: String
    let contentFontSize: CGFloat
    let contentLineHeight: CGFloat
    let contentKern: CGFloat
    
    init(titleFontName: String, titleFontSize: CGFloat, titleLineHeight: CGFloat, titleKern: CGFloat, contentFontName: String, contentFontSize: CGFloat, contentLineHeight: CGFloat, contentKern: CGFloat) {
        self.titleFontName = titleFontName
        self.titleFontSize = titleFontSize
        self.titleLineHeight = titleLineHeight
        self.titleKern = titleKern
        self.contentFontName = contentFontName
        self.contentFontSize = contentFontSize
        self.contentLineHeight = contentLineHeight
        self.contentKern = contentKern
    }
    
    func getTitleFont() -> UIFont {
        return UIFont(name: titleFontName, size: titleFontSize) ?? UIFont.systemFont(ofSize: titleFontSize)
    }
    
    func getContentFont() -> UIFont {
        return UIFont(name: contentFontName, size: contentFontSize) ?? UIFont.systemFont(ofSize: contentFontSize)
    }
    
    func getTitleAtts(baseOn attrs: [NSAttributedString.Key : Any]? ) -> [NSAttributedString.Key : Any] {
        var newAttrs = attrs ?? [NSAttributedString.Key : Any]()
        newAttrs[.paragraphStyle] = createParagraphStyle(font: getTitleFont(), lineHeight: titleLineHeight)
        newAttrs[.kern] = titleKern
        return newAttrs
    }
    
    func getContentAtts(baseOn attrs: [NSAttributedString.Key : Any]?) -> [NSAttributedString.Key : Any] {
        var newAttrs = attrs ?? [NSAttributedString.Key : Any]()
        newAttrs[.paragraphStyle] = createParagraphStyle(font: getContentFont(), lineHeight: contentLineHeight)
        newAttrs[.kern] = contentKern
        return newAttrs
    }
    
    private func createParagraphStyle(font: UIFont, lineHeight: CGFloat) -> NSParagraphStyle {
        let minLineHeight = font.pointSize
        let lineSpacing: CGFloat = lineHeight - minLineHeight
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        return paragraphStyle
    }
}
