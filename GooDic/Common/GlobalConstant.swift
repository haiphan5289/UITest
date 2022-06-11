//
//  GlobalConstant.swift
//  GooDic
//
//  Created by ttvu on 6/1/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

struct GlobalConstant {
    static let presentationGap: CGFloat = UIApplication.shared.statusBarHeight
    
    // MARK: - Appsflyer info & App info
    static let appsFlyerDevKey = "c6ZmxC4oD6hhkr2icKFRnW"
    static let appleAppID = "1515861951"
    static var appItunesString: String {
        "https://itunes.apple.com/app/id\(GlobalConstant.appleAppID)"
    }
    
    // MARK: - API and WebView
    static let userAgent = " GooDictApp"
    
    // MARK: - URLs
    static let agreementURL = Environment.webScheme + Environment.wvHost + "/info/idraft/term.html"
    static let feedbackURL = Environment.wvScheme + Environment.wvHost + Environment.wvFeedbackPath
    static let notificationURL = Environment.webScheme + Environment.webHost + "/info.html"
    static let helpURL = Environment.webScheme + Environment.webHost + "/help.html"
    static let termURL = Environment.webScheme + Environment.wvHost + "/info/idraft/term.html"
    static let appPolicyURL = Environment.webScheme + Environment.wvHost + "/info/idraft/privacy.html"
    static let privacyPolicyURL = "https://www.nttr.co.jp/privacy_policy/"
    static let personalDataPolicyURL = "https://www.nttr.co.jp/personal_data_policy/"
    static let openLicenseURL = Environment.webScheme + Environment.webHost + "/license.html"
    static let errorInfoURL = "https://help.goo.ne.jp/cc/app/m/96200/"
    static let commercialTransactions = Environment.webScheme + Environment.wvHost + "/info/idraft/law.html"
    static let cancelSubscription = Environment.webScheme + Environment.webHost + "/cancellation.html"
    static let storePaymentURL = "https://store.goo.ne.jp/account"
    static let premiumURl = Environment.webScheme + Environment.webHost + "/premium.html"
    static let gooTwitterUrl  = "https://twitter.com/goojisho"
     
    // MARK: - In-app message
    static let iamOpenHomeViewTrigger = "open_home_view"
    static let billingRequestUri = "goodict://billing_request"
    
    /// the tooltip 's going to auto-hide after `tooltipDuration` second(s),
    static let tooltipDuration: Int = 3
    
    // Request settings
    static let requestTimeout: Int = 10
    static let requestRetry: Int = 3
    static let limitItemPerPage: Int = 20
    static let maxItemPerPage: Int = 100
    
    static let nameDevicePC: String = "WEB"
    static let limitDevice: Int = 2
    static let spacingParagraphStyle: CGFloat = 5
}

enum AppURI {
    case home
    case folder
    case search
    case menu
    case info
    case help
    case terms
    case appPolicy
    case privacyPolicy
    case personalDataPolicy
    case openLicense
    case registerDevice
    case homeCloud
    case billingRequest
    case webURL(URL)
    
    init?(rawValue: String) {
        switch rawValue {
        case "goodict://home":
            self = .home
        case "goodict://folder":
            self = .folder
        case "goodict://search":
            self = .search
        case "goodict://menu":
            self = .menu
        case "goodict://info":
            self = .info
        case "goodict://help":
            self = .help
        case "goodict://terms":
            self = .terms
        case "goodict://apppolicy":
            self = .appPolicy
        case "goodict://privacypolicy":
            self = .privacyPolicy
        case "goodict://personaldatapolicy":
            self = .personalDataPolicy
        case "goodict://openlicense":
            self = .openLicense
        case "goodict://device_setting":
            self = .registerDevice
        case "goodict://home_cloud":
            self = .homeCloud
        case GlobalConstant.billingRequestUri:
            self = .billingRequest
        default:
            if let url = URL(string: rawValue) {
                self = .webURL(url)
            } else {
                return nil
            }
        }
    }
}
