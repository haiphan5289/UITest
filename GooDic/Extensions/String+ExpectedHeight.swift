//
//  String+ExpectedHeight.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension String {
    func expectedHeight(withWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return boundingBox.height
    }
    
    func expectedWidth(withHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return boundingBox.width
    }
    
    func expectedSize(withWidth width: CGFloat, font: UIFont) -> CGSize {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return boundingBox.size
    }
    
    func size(withFont font: UIFont) -> CGSize {
        let string = NSString(string: self)
        let size = string.size(withAttributes: [NSAttributedString.Key.font: font])
        return size
    }
    func toDate(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
}

extension String {
    
    enum FormatDate: String, CaseIterable {
        case yyyyMMddHHmmss = "yyyyMMddHHmmss"
        case HHmmssddMMyyyy = "HH:mm:ss dd/MM/yyyy"
        case yyyyMMdd = "yyyy-MM-dd"
        case HHmm = "HH:mm"
        case MMddyyyy = "MM/dd/yyyy"
        case ddMMyyyy = "dd/MM/yyyy"
        case MMddyyyyHHmmss = "MM/dd/yyyy HH:mm:ss"
    }
    
    func convertToDate() -> Date? {
        var date: Date?
        FormatDate.allCases.forEach { format in
            if date != nil {
                return
            }
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC+9") //time japan
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = format.rawValue
            date = dateFormatter.date(from: self)
            
        }
        return date
    }
    
    func applicationVersionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."
        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        if zeroDiff == 0 {
            // Same format, compare normally
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}

extension Date {
    private static let formatDateDefault = DateFormatter()
    func covertToString(format: String.FormatDate) -> String {
        Date.formatDateDefault.locale = .current
        Date.formatDateDefault.timeZone = TimeZone(abbreviation: "UTC+9")
        Date.formatDateDefault.locale = Locale(identifier: "en_US_POSIX")
        Date.formatDateDefault.dateFormat = format.rawValue
        let result = Date.formatDateDefault.string(from: self)
        return result
    }
    
    func covertToDate(format: String.FormatDate) -> Date? {
        Date.formatDateDefault.locale = .current
        Date.formatDateDefault.timeZone = TimeZone(abbreviation: "UTC+9")
        Date.formatDateDefault.locale = Locale(identifier: "en_US_POSIX")
        Date.formatDateDefault.dateFormat = format.rawValue
        let result = Date.formatDateDefault.date(from: self.covertToString(format: format))
        return result
    }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
}
