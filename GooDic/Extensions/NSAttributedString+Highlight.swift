//
//  NSAttributedString+Highlight.swift
//  GooDic
//
//  Created by ttvu on 5/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension NSAttributedString {
    convenience init(base: String,
                     keyWords: [String],
                     foregroundColor: UIColor,
                     font: UIFont,
                     highlightForeground: UIColor,
                     highlighBackground: UIColor) {
        let baseAttributed = NSMutableAttributedString(string: base,
                                                       attributes: [NSAttributedString.Key.font: font,
                                                                    NSAttributedString.Key.foregroundColor: foregroundColor])
        let range = NSRange(location: 0, length: base.utf16.count)
        for word in keyWords {
            guard let regex = try? NSRegularExpression(pattern: word, options: .caseInsensitive) else {
                continue
            }
            
            regex
                .matches(in: base, options: .withTransparentBounds, range: range)
                .forEach { baseAttributed
                    .addAttributes([NSAttributedString.Key.backgroundColor: highlighBackground,
                                    NSAttributedString.Key.foregroundColor: highlightForeground],
                                   range: $0.range) }
        }
        self.init(attributedString: baseAttributed)
    }
    
    convenience init(base: String,
                     keyWord: String,
                     keyWordIndex: Int,
                     foregroundColor: UIColor,
                     font: UIFont,
                     highlightForeground: UIColor,
                     highlighBackground: UIColor) {
        let baseAttributed = NSMutableAttributedString(string: base,
                                                       attributes: [NSAttributedString.Key.font: font,
                                                                    NSAttributedString.Key.foregroundColor: foregroundColor])
        let range = NSRange(location: 0, length: base.utf16.count)
        
        if let regex = try? NSRegularExpression(pattern: keyWord, options: .caseInsensitive) {
            let list = regex
                .matches(in: base, options: .withTransparentBounds, range: range)
            
            if keyWordIndex < list.count {
                let item = list[keyWordIndex]
                baseAttributed
                    .addAttributes([NSAttributedString.Key.backgroundColor: highlighBackground,
                                    NSAttributedString.Key.foregroundColor: highlightForeground],
                                   range: item.range)
                
            }
        }
        
        
        
        self.init(attributedString: baseAttributed)
    }
}
