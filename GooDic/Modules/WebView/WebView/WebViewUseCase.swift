//
//  WebViewUseCase.swift
//  GooDic
//
//  Created by haiphan on 14/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol WebViewUseCaseProtocol {
    func notìyWeb() -> Observable<NotiWebModel?>
}

struct WebViewUseCase: WebViewUseCaseProtocol, AuthenticationUseCaseProtocol {
    
    @GooInject var remoteConfigService: RemoteConfigService
        
    func notìyWeb() -> Observable<NotiWebModel?> {
        return remoteConfigService.gateway.notifyWebview()
    }
}
