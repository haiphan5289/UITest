//
//  Bundle+Extension.swift
//  GooDic
//
//  Created by ttvu on 6/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

extension Bundle {
    // Name of the app - title under the icon.
    var displayName: String? {
        guard let dict = self.infoDictionary else { return nil }
        
        return dict["CFBundleDisplayName"] as? String ?? dict["CFBundleName"] as? String
    }
    
    var applicationVersion: String {
        guard let dict = self.infoDictionary else { return "" }
        
        return (dict["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    var applicationBuild: String {
        guard let dict = self.infoDictionary else { return "" }
        
        return (dict[kCFBundleVersionKey as String] as? String) ?? ""
    }
}
