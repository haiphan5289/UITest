//
//  BillingInfo.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/3/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//
import Foundation

struct BillingInfo: Codable {
    var platform: String
    var billingStatus: BillingStatus = .free
    
    func platformDislay() -> String {
        if platform == "apple" { return L10n.AccountInfo.Premium.apple }
        if platform == "googleplay" { return L10n.AccountInfo.Premium.android }
        return L10n.AccountInfo.Premium.other
    }
    
    func isGooPayment() -> Bool {
        if platform == "apple" { return false }
        if platform == "googleplay" { return false }
        return true
    }
    
    func storePaymentString() -> String {
        if platform == "apple" { return L10n.Premium.apple }
        if platform == "googleplay" { return L10n.Premium.android }
        return ""
    }
}
