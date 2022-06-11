//
//  UserInfo.swift
//  GooDic
//
//  Created by ttvu on 12/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import UIKit

enum DeviceStatus: Int, Codable {
    case unknown = 0
    case registered = 1
    case unregistered = 2
}

struct UserInfo: Codable {
    var name: String
    var deviceStatus: DeviceStatus = .unknown
    var billingStatus: BillingStatus?
}

enum NameFont: String, Codable {
    case hiraginoSansW4
    case hiraginoMinchoW3
    
    var toTracking: String {
        switch self {
        case .hiraginoSansW4:
            return "ゴシック"
        default:
            return "明朝"
        }
    }
}

enum SizeFont: Double, CaseIterable, Codable {
    case eighty = 11
    case ninety = 13
    case onehundred = 14
    case onehundredTen = 15
    case onehundredTwenty = 17
    case onehundredThirty = 18.2
    
    var text: String {
        switch self {
        case .eighty:
            return "80%"
        case .ninety:
            return "95%"
        case .onehundred:
            return "100%"
        case .onehundredTen:
            return "105%"
        case .onehundredTwenty:
            return "115%"
        case .onehundredThirty:
            return "130%"
        }
    }
    
    var toTracking: String {
        switch self {
        case .eighty:
            return "80"
        case .ninety:
            return "95"
        case .onehundred:
            return "100"
        case .onehundredTen:
            return "105"
        case .onehundredTwenty:
            return "115"
        case .onehundredThirty:
            return "130"
        }
    }
}

struct SettingFont: Codable {
    
    enum StatusHighlight {
        case search, replace, other, noColor
    }
    
    let size: SizeFont
    let name: NameFont
    let show: String
    let isEnableButton: Bool
    let autoSave: Bool?
    
    static let defaultValue = SettingFont(size: SizeFont.onehundred, name: NameFont.hiraginoSansW4, isEnableButton: true, autoSave: false)
    
    init(size: SizeFont, name: NameFont, isEnableButton: Bool, autoSave: Bool = false) {
        self.size = size
        self.name = name
        self.isEnableButton = isEnableButton
        self.autoSave = autoSave
        
        if let type = SizeFont(rawValue: Double(size.rawValue)) {
            self.show = type.text
        } else {
            self.show = "100%"
        }
    }
    
    func getTextValue() -> String {
        return "\(self.name.toTracking) \(self.size.text)"
    }
    
    func getFont() -> UIFont {
        switch name {
        case .hiraginoSansW4:
            return UIFont.hiraginoSansW4(size: CGFloat(self.size.rawValue))
        case .hiraginoMinchoW3:
            return UIFont.hiraginoMinchoW3(size: CGFloat(self.size.rawValue))
        }
    }
    
    func getContentLineHeight() -> CGFloat {
        switch self.size {
        case .eighty:
            return 18.7
        case .ninety:
            return 22.1
        case .onehundred:
            return 23.8
        case .onehundredTen:
            return 25.5
        case .onehundredTwenty:
            return 28.9
        case .onehundredThirty:
            return 30.94
        }
        
    }

    func getContentAtts(baseOn attrs: [NSAttributedString.Key : Any]?) -> [NSAttributedString.Key : Any] {
        var newAttrs = attrs ?? [NSAttributedString.Key : Any]()
        newAttrs[.paragraphStyle] = createParagraphStyle(font: self.getFont(), lineHeight: self.getContentLineHeight())
        newAttrs[.kern] = 0
        return newAttrs
    }
    
    func getContentAttsSearch(baseOn attrs: [NSAttributedString.Key : Any]?,
                              statusHighlight: StatusHighlight) -> [NSAttributedString.Key : Any] {
        var newAttrs = attrs ?? [NSAttributedString.Key : Any]()
        newAttrs[.paragraphStyle] = createParagraphStyle(font: self.getFont(), lineHeight: self.getContentLineHeight())
        newAttrs[.kern] = 0
        newAttrs[.font] = self.getFont()
        
        switch statusHighlight {
        case .search:
            newAttrs[.backgroundColor] = Asset.textSearch.color
        case .replace:
            newAttrs[.backgroundColor] = Asset.textReplace.color
        case .noColor: break
        default:
            newAttrs[.backgroundColor] = UIColor.clear
        }
        newAttrs[.foregroundColor] = Asset.textPrimary.color
        return newAttrs
    }
    
    func getMaskContentAttsSearch(baseOn attrs: [NSAttributedString.Key : Any]?,
                              statusHighlight: StatusHighlight) -> [NSAttributedString.Key : Any] {
        var newAttrs = attrs ?? [NSAttributedString.Key : Any]()
        newAttrs[.paragraphStyle] = createParagraphStyle(font: self.getFont(), lineHeight: self.getContentLineHeight())
        newAttrs[.kern] = 0
        newAttrs[.font] = self.getFont()
        
        switch statusHighlight {
        case .search:
            newAttrs[.backgroundColor] = Asset.textSearch.color
        case .replace:
            newAttrs[.backgroundColor] = Asset.textReplace.color
        case .noColor: break
        default:
            newAttrs[.backgroundColor] = UIColor.clear
        }
        newAttrs[.foregroundColor] = Asset.textPrimary.color
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

struct SettingSearch: Codable {
    let isSearch: Bool
    let isReplace: Bool
    let billingStatus: BillingStatus
    
    init(isSearch: Bool, isReplace: Bool, billingStatus: BillingStatus) {
        self.isSearch = isSearch
        self.isReplace = isReplace
        self.billingStatus = billingStatus
        
        
    }
}
