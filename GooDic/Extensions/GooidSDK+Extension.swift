//
//  GooidSDK+Extension.swift
//  GooDic
//
//  Created by ttvu on 12/1/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import GooidSDK

extension GooidSDK {
    func generateCookies() -> String? {            
        let cookieValue = gooidTicket()?.httpsCookies
            .map({cookie in
                return "\(cookie.name)=\(cookie.value);"
            })
            .joined(separator: " ")
        
        return cookieValue
    }
    
    func generateCookiesIncludeBillingStatus() -> String? {
        let cookieValue = gooidTicket()?.httpsCookies
            .map({cookie in
                return "\(cookie.name)=\(cookie.value);"
            })
            .joined(separator: " ")
        if var cook = cookieValue {
            cook += " billing_status=\(AppManager.shared.billingInfo.value.billingStatus.rawValue);"
            return cook
        }
        return cookieValue
    }
    
    var isLoggedIn: Bool {
        gooidTicket()?.isEmpty == false
    }
}
