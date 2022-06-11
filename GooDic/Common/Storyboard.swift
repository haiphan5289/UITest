//
//  Storyboard.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

enum Storyboard: String {
    case app = "App" // fake splash
    case main = "Main"
    case home = "Home"
    case dictionary = "Dictionary"
    case menu = "Menu"
    case creation = "Creation"
    case suggestion = "Suggestion"
    case alert = "Alert"
    case agreement = "Agreement"
    case tutorial = "Tutorial"
    case folder = "Folder"
    case login = "Login"
    case registrationLogout = "RegistrationForceLogout"
    case registerDevice = "RegisterDevice"
    case logOut = "RegisterDeviceLogout"
    case setting = "Setting"
    case settingSearch = "SettingSearch"
    case registerPremium = "RegisterPremium"
    case accountInfo = "AccountInfo"
    case advancedDictionary = "AdvancedDictionary"
    case sort = "Sort"
    case draw = "DrawPresent"
    case settingEnviromental = "SettingEnviromental"
    case backup = "Backup"
    
    
    var storyboard: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: nil)
    }
}

protocol ViewControllerLoadable {
    static func instantiate(storyboard: Storyboard) -> Self
}

extension UIViewController: ViewControllerLoadable {}

extension ViewControllerLoadable where Self: UIViewController {
    static func instantiate(storyboard: Storyboard) -> Self {
        let id = String(describing: Self.self)
        let vcStoryboard = storyboard.storyboard
                 
        let vc = vcStoryboard.instantiateViewController(withIdentifier: id) as! Self
        return vc
    }
}

extension UIStoryboard {
    static func loadViewController<T>(name: String = String(describing: T.self), bundle: Bundle? = nil) -> T {
        return UIStoryboard(name: name, bundle: bundle).instantiateInitialViewController() as! T
    }
}
