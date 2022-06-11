//
//  NotificationBannerHome.swift
//  GooDic
//
//  Created by Nguyen Vu Hao on 18/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import FirebaseFirestore

public struct NotificationBannerHome: Codable {
    
    private let textNewLineFireStore = "\\n"
    private let textNewLine = "\n"
    
    let endDate: Date?
    let startDate: Date?
    let content: String?
    let uriScheme: String?
    let version: Int?
    let distributionIOS : Bool?

    enum CodingKeys: String, CodingKey {
        case endDate = "period_end"
        case startDate = "period_start"
        case version = "version"
        case uriScheme = "transition_url"
        case content = "message_text"
        case distributionIOS = "distribution_ios"
    }
    
    func titleBannerToShow() -> String? {
        guard let expireDate = endDate,
              let startDate = startDate,
              let version = version,
              let titleValue = content,
              let distributionIOS = self.distributionIOS else {
            return nil
        }
        
        if !distributionIOS {
            return nil
        }
        
        if expireDate.timeIntervalSince(Date()) < 0 {
            return nil
        }
        
        if startDate.timeIntervalSince(Date()) > 0 {
            return nil
        }
        
        let formatTitle = titleValue.replacingOccurrences(of: textNewLineFireStore, with: textNewLine)
        let titleForIpad = formatTitle.replacingOccurrences(of: textNewLine, with: "")
        
        if AppSettings.lastVersionNotiHomeBanner != version {
            AppSettings.isUserHasBeenCloseHomeBanner = false
            AppSettings.lastVersionNotiHomeBanner = version
            AppSettings.expirationDateHomeBanner = expireDate
            if UIDevice.current.userInterfaceIdiom == .pad {
                return titleForIpad
            }
            return formatTitle
        }
        
        if AppSettings.isUserHasBeenCloseHomeBanner {
            return nil
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return titleForIpad
        }
        return formatTitle
    }
}
