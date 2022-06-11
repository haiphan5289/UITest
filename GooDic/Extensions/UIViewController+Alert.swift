//
//  UIViewController+Alert.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIViewController {
    
    enum SetupNavigationTitle {
        case draft, suggestion, settingFont, settingSearch, requestPremium, dictionary, folderBrowser, localFolderSelection, naviWebview, feedBackWebView, advanceDictionary, sort, backUpSetting
    }
    
    func alert(message: String, title: String = "", okActionTitle: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: okActionTitle, style: .cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setupNavigationTitle(type: SetupNavigationTitle) {
        switch type {
        case .draft:
            if #available(iOS 15.0, *) {
                self.setupNavigationiOS15(font: UIFont.hiraginoSansW4(size: 11), isBackground: false)
            } else {
                let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 11)]
                navigationController?.navigationBar.titleTextAttributes = atts
            }
        case .folderBrowser:
            if #available(iOS 15.0, *) {
                self.setupNavigationiOS15(font: UIFont.hiraginoSansW6(size: 18), isBackground: true)
            } else {
                navigationController?.navigationBar.isTranslucent = false
                navigationController?.navigationBar.barTintColor = Asset.naviBarBgModel.color
            }
        default:
            if #available(iOS 15.0, *) {
                self.setupNavigationiOS15(font: UIFont.hiraginoSansW4(size: 15), isBackground: true)
            } else {
                let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 15)]
                navigationController?.navigationBar.titleTextAttributes = atts
                navigationController?.navigationBar.isTranslucent = false
                navigationController?.navigationBar.barTintColor = Asset.naviBarBgModel.color
            }
        }
    }
    
    private func setupNavigationiOS15(font: UIFont, isBackground: Bool) {
        if #available(iOS 15.0, *) {
            let atts = [NSAttributedString.Key.font: font]
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = atts
            if isBackground {
                appearance.backgroundColor = Asset.naviBarBgModel.color
            } else {
                appearance.backgroundColor = Asset.ffffff121212.color
            }
            if let navBar = self.navigationController {
                let bar = navBar.navigationBar
                bar.standardAppearance = appearance
                bar.scrollEdgeAppearance = appearance
            }
            
        }
    }

}

