//
//  AlertNavigatorProtocol.swift
//  GooDic
//
//  Created by ttvu on 6/12/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit.UIViewController

protocol AlertNavigatorProtocol {
    var viewController: UIViewController! { get set }
    func toConnectionAlert(message: String)
    func toServerBusyAlert()
}

extension AlertNavigatorProtocol {
    func toConnectionAlert(message: String) {
//        #if DEBUG
//        let newMessage = message.isEmpty ? L10n.Alert.Network.message : message + "\n" + L10n.Alert.Network.message
//        #else
        let newMessage = L10n.Alert.Network.message
//        #endif
        
        viewController.alert(message: newMessage,
                             title: L10n.Alert.Network.title,
                             okActionTitle: L10n.Alert.ok)
    }
    
    func toServerBusyAlert() {
        viewController.alert(message: L10n.Alert.Server.message,
                             title: L10n.Alert.Server.title,
                             okActionTitle: L10n.Alert.ok)
    }
}
