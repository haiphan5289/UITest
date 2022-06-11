//
//  ToastMessageFixModel.swift
//  GooDic
//
//  Created by haiphan on 14/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

struct ToastMessageFixModel: Codable {
    
    enum ShowStatus {
        case first, version, greaterSpanDays, hide
        
        static func getStatus(isTap: Bool,version: Int, spanDays: Int, isNotifWebView: Bool, model: ToastMessageFixModel) -> Self {
            
            if !isTap {
                return .first
            }
            
            let currentDate = Date().covertToDate(format: .MMddyyyy)
            
            if isNotifWebView {
                if ( version > (model.versionOfToastNotifWebView ?? 0)) {
                    return .version
                }
                
                if let currentDate = currentDate, let dateOfToastNotifWebView = AppSettings.showToastMgs.spanDaysToastNotifWebView?.covertToDate(format: .MMddyyyy), let date =  Calendar.current.date(byAdding: .day, value: spanDays, to: dateOfToastNotifWebView) {
                    if (currentDate >= date) {
                        return.greaterSpanDays
                    }
                }
            } else {
                if ( version > (model.versionOfToastAdvancedDictionary ?? 0)) {
                    return .version
                }
                
                if let currentDate = currentDate, let dateOfToastAdvancedDictionary = AppSettings.showToastMgsDictionary.spanDaysToastAdvancedDictionary?.covertToDate(format: .MMddyyyy), let date =  Calendar.current.date(byAdding: .day, value: spanDays, to: dateOfToastAdvancedDictionary) {
                    if (currentDate >= date) {
                        return.greaterSpanDays
                    }
                }
            }
            
            return .hide
            
        }
    }
    
    let isTap: Bool
    let spanDaysToastNotifWebView: Date?
    let spanDaysToastAdvancedDictionary: Date?
    let versionOfToastNotifWebView: Int?
    let versionOfToastAdvancedDictionary: Int?
    
    init(isTap: Bool, versionToastNotifWebView: Int?, versionToastAdvancedDictionary: Int?, spanDaysOfToastNotifWebView: Date?, spanDaysOfToastAdvancedDictionary: Date?) {
        self.isTap = isTap
        self.spanDaysToastNotifWebView = spanDaysOfToastNotifWebView
        self.spanDaysToastAdvancedDictionary = spanDaysOfToastAdvancedDictionary
        self.versionOfToastAdvancedDictionary = versionToastAdvancedDictionary
        self.versionOfToastNotifWebView = versionToastNotifWebView
    }
    
    func isShowView(version: Int, spanDays: Int, isNotifWebView: Bool) -> Bool {
        let status = ShowStatus.getStatus(isTap: self.isTap, version: version, spanDays: spanDays, isNotifWebView: isNotifWebView, model: self)
        switch  status {
        case .hide: return false
        case .first, .version, .greaterSpanDays: return true
        }
    }
    
    static let valueDefault = ToastMessageFixModel(isTap: false, versionToastNotifWebView: 0, versionToastAdvancedDictionary: 0, spanDaysOfToastNotifWebView: Date(), spanDaysOfToastAdvancedDictionary: Date())
}

public struct NotiWebModel: Codable {
    let button: String?
    let content: String?
    let spanDays: Int?
    let version: Int?
    
    enum CodingKeys: String, CodingKey {
        case button = "button_text"
        case content = "message_text"
        case spanDays = "span_days"
        case version = "version"
    }
}
