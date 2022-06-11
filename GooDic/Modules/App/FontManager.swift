//
//  FontManager.swift
//  GooDic
//
//  Created by ttvu on 9/7/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

class FontManager {
    static let shared = FontManager()
    
    lazy var fontStyleDataList: [FontStyleData] = load("FontStyleDataList.json") ?? []
    
    let defaultFontStyle = FontStyleData(titleFontName: "HiraginoSans-W4",
                                         titleFontSize: 17,
                                         titleLineHeight: 26,
                                         titleKern: 0,
                                         contentFontName: "HiraginoSans-W4",
                                         contentFontSize: 14,
                                         contentLineHeight: 25.2,
                                         contentKern: 0)
    
    var currentLevel: Int {
        return AppSettings.fontStyleLevel
    }
    
    var numOfLevels: Int {
        return fontStyleDataList.count
    }
    
    var currentFontStyle: FontStyleData {
        if currentLevel < fontStyleDataList.count {
            return fontStyleDataList[currentLevel]
        }
        
        return defaultFontStyle
    }
    
    private init() {}
}
