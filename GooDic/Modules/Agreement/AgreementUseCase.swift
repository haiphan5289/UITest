//
//  AgreementUseCase.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

protocol AgreementUseCaseProtocol {
    func setAgreementDate(_ date: Date)
    func isFirstRun() -> Bool
    func isApplicationPrivacyPolicyURL(_ url: URL) -> LinkData?
}

struct AgreementUseCase: AgreementUseCaseProtocol {
    
    func setAgreementDate(_ date: Date) {
        AppSettings.agreementDate = date
    }
    
    func isFirstRun() -> Bool {
        return AppSettings.firstRun
    }
    
    func isApplicationPrivacyPolicyURL(_ url: URL) -> LinkData? {
        let targetURL = "https://goo-dict.web.app/privacy.html"
        
        if url.absoluteString == targetURL {
            return LinkData(title: L10n.Menu.Cell.appPrivacyPolicy,
                            sceneType: GATracking.Scene.appPolicy,
                            cachePolicy: .reloadIgnoringCacheData,
                            ulr: targetURL)
        }
        
        return nil
    }
}
