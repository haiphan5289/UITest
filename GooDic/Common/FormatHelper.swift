//
//  FormatHelper.swift
//  GooDic
//
//  Created by ttvu on 5/28/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

struct FormatHelper {
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
//        formatter.dateFormat = "hh:mm:ss"
        return formatter
    }
    
    static var dateFullFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd hh:mm:ss" 
        return formatter
    }
    
    static var dateFormatterOnCloud: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(abbreviation: "UTC+9") // Japan timezone
        return formatter
    }
    
    static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        return formatter
    }
    
    static var dateFormatterOnGatewayCloud: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(abbreviation: "UTC+9") // Japan timezone
        formatter.locale = Locale(identifier: "en_US_POSIX") // Fix format for 12h|24h
        return formatter
    }
}

extension Date {
    var toString: String {
        return FormatHelper.dateFormatter.string(from: self)
    }
}
