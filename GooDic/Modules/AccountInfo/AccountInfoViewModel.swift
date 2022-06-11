//
//  AccountInfoViewModel.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/1/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct AccountInfoViewModel {
    let useCase: AccountInfoUseCaseProtocol
    let navigator: AccountInfoNavigateProtocol
    
    init(useCase: AccountInfoUseCaseProtocol, navigator: AccountInfoNavigateProtocol) {
        self.useCase = useCase
        self.navigator = navigator
    }
}

extension AccountInfoViewModel: ViewModelProtocol {
    struct Input {
        let actionTrigger: Driver<Void> // logout
        let subcriptionTrigger: Driver<Void>
    }
    
    struct Output {
        let logoutAccount: Driver<Void>
        let subcriptionAction: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let activityIndicator = ActivityIndicator()
        let logoutAccount = input.actionTrigger
            .withLatestFrom(activityIndicator)
            .filter({ $0 == false })
            .mapToVoid()
            .flatMapLatest({ self.useCase.hasLoggedin().asDriverOnErrorJustComplete() })
            .flatMap({ (isLoggedin) -> Driver<Void> in
                return self.navigator.toLogoutConfirmation()
                    .filter({ $0 })
                    .asDriverOnErrorJustComplete()
                    .flatMap({ _ in self.useCase.logout().asDriverOnErrorJustComplete().mapToVoid() })
            }).asDriver()
        
        let actionTrigger = input.subcriptionTrigger
            .do(onNext: { (obj) in
                if let url = URL(string: GlobalConstant.cancelSubscription) {
                    self.navigator.toWebView(url: url, cachePolicy: .reloadIgnoringCacheData, title: L10n.Premium.Cancel.subcription, sceneType: GATracking.Scene.cancelSubcription, internalLinkDatas: nil)
                }
            }).mapToVoid()

        return Output(logoutAccount: logoutAccount, subcriptionAction: actionTrigger)
    }
}
