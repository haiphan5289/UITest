//
//  FileStoreBillingText.swift
//  GooDic
//
//  Created by Nguyen Vu Hao on 11/11/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

public struct FileStoreBillingText: Codable {
    
    let confirmButton: String?
    let registerButtonLogin: String?
    let registerButtonLogin2ndLine: String?
    let registerButtonNoLogin: String?
    let registerButtonNoLogin2ndLine: String?

    enum CodingKeys: String, CodingKey {
        case confirmButton = "confirm_button"
        case registerButtonLogin = "regist_button_login"
        case registerButtonNoLogin = "regist_button_nologin"
        case registerButtonLogin2ndLine = "regist_button_login_2nd_line"
        case registerButtonNoLogin2ndLine = "regist_button_nologin_2nd_line"
    }
    
    func titleDisplay(isLogin: Bool, isConfirmScreen: Bool = false) -> String? {
        if isLogin == false {
            return registerButtonNoLogin
        }
        if isConfirmScreen {
            return confirmButton
        }
        return registerButtonLogin
    }
    
    func titleBottomDisplay(isLogin: Bool) -> String? {
        if isLogin == false {
            return registerButtonNoLogin2ndLine
        }
        return registerButtonLogin2ndLine
    }
}
