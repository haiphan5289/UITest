//
//  MenuConfig.swift
//  GooDic
//
//  Created by ttvu on 5/22/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

func createMenuData() -> [MenuData] {
    let data: [MenuData] = [
        MenuData(title: L10n.Menu.Cell.Item.premiumLimited,
                 sceneType: GATracking.Scene.requestPremium,
                 icon: Asset.icPremium.image,
                 action: .registerSubscription),
        MenuData(title: L10n.Menu.Cell.notification,
                 sceneType: GATracking.Scene.info,
                 icon: Asset.icNotifi.image,
                 action: .openWebView(GlobalConstant.notificationURL,
                                      .reloadIgnoringCacheData,
                                      nil)),
        MenuData(title: L10n.Menu.Cell.trash,
                 sceneType: GATracking.Scene.trash,
                 icon: Asset.icTrash.image,
                 action: .openTrash),
        MenuData(title: L10n.Menu.Cell.setting,
                 sceneType: GATracking.Scene.setting,
                 icon: Asset.icSetting.image,
                 action: .openSetting),
        MenuData(title: L10n.Menu.Cell.shareChargePC,
                 sceneType: GATracking.Scene.unknown,
                 icon: Asset.icMenuPremium.image,
                 action: .share(L10n.Menu.Share.Charge.pc)),
        MenuData(title: L10n.Menu.Cell.share,
                 sceneType: GATracking.Scene.unknown,
                 icon: Asset.icFriends.image,
                 action: .share(GlobalConstant.appItunesString)),
        MenuData(title: L10n.Menu.Cell.help,
                 sceneType: GATracking.Scene.help,
                 icon: Asset.icHelp.image,
                 action: .openWebView(GlobalConstant.helpURL,
                                      .reloadIgnoringCacheData,
                                        [LinkData(title: "",
                                                  sceneType: GATracking.Scene.appPolicy,
                                                  cachePolicy: .reloadIgnoringCacheData,
                                                  ulr: GlobalConstant.billingRequestUri)])),
        MenuData(title: L10n.Menu.Cell.openGooTwitter,
                 sceneType: GATracking.Scene.twitter,
                 icon: Asset.icSns.image,
                 action: .openGooTwitter),
        MenuData(title: L10n.Menu.Cell.terms,
                 sceneType: GATracking.Scene.terms,
                 icon: Asset.icTerm.image,
                 action: .openWebView(GlobalConstant.termURL,
                                      .reloadIgnoringCacheData,
                                      [LinkData(title: L10n.Menu.Cell.appPrivacyPolicy,
                                                sceneType: GATracking.Scene.appPolicy,
                                                cachePolicy: .reloadIgnoringCacheData,
                                                ulr: GlobalConstant.appPolicyURL),
                                       LinkData(title: L10n.Menu.Cell.commercialTransactions,
                                                sceneType: GATracking.Scene.law,
                                                 cachePolicy: .reloadIgnoringCacheData,
                                                 ulr: GlobalConstant.commercialTransactions),
                                      ])), // always "goo-dict.web.app"
        MenuData(title: L10n.Menu.Cell.appPrivacyPolicy,
                 sceneType: GATracking.Scene.appPolicy,
                 icon: Asset.icAppPrivacy.image,
                 action: .openWebView(GlobalConstant.appPolicyURL,
                                      .reloadIgnoringCacheData,
                                      nil)),
        MenuData(title: L10n.Menu.Cell.commercialTransactions,
                 sceneType: GATracking.Scene.law,
                 icon: Asset.icCommercial.image,
                 action: .openWebView(GlobalConstant.commercialTransactions,
                                      .reloadIgnoringCacheData,
                                      nil)),
        MenuData(title: L10n.Menu.Cell.personalInformation,
                 sceneType: GATracking.Scene.personalDataPolicy,
                 icon: Asset.icPersonal.image,
                 action: .openWebView(GlobalConstant.personalDataPolicyURL,
                                      .useProtocolCachePolicy,
                                      nil))
    ]
    
    return data
}

enum MenuAction {
    case openWebView(String, URLRequest.CachePolicy, [LinkData]?) // url, cachePolicy, internal links
    case share(String)
    case openTrash
    case registerSubscription
    case openGooTwitter
    case openSetting
}

struct MenuData {
    var title: String
    var sceneType: GATracking.Scene
    var icon: UIImage
    var action: MenuAction
    
    init(title: String, sceneType: GATracking.Scene, icon: UIImage, action: MenuAction) {
        self.title = title
        self.sceneType = sceneType
        self.icon = icon
        self.action = action
    }
}
