//
//  WebViewVM.swift
//  GooDic
//
//  Created by haiphan on 14/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct WebViewVM {
    var navigator: WebCoordinatorProtocol
    var useCase: WebViewUseCaseProtocol
}

extension WebViewVM: ViewModelProtocol {
    struct Input {
        let eventTapToastView: Driver<ToastMessageFixView.TapAction>
        let eventDismiss: Driver<Void>
        let getNotifyWebTrigger: Driver<Void>
    }
    
    struct Output {
        let getBillingInfo: Driver<BillingInfo>
        let eventTapToastView: Driver<ToastMessageFixView.TapAction>
        let getNotifyWeb: Driver<NotiWebModel?>
        let eventDismiss: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let getResultNotifyWeb = PublishSubject<NotiWebModel?>.init()
        let getNotifyWeb = input.getNotifyWebTrigger
            .asObservable()
            .flatMap({
                self.useCase.notìyWeb()
            })
            .do { notifModel  in
                getResultNotifyWeb.onNext(notifModel)
            }
        
        
        
        let getBillingInfo = AppManager.shared.billingInfo
            .asDriverOnErrorJustComplete()
        
        let eventTapToastView = input.eventTapToastView
            .withLatestFrom(getResultNotifyWeb.asObservable().asDriverOnErrorJustComplete(), resultSelector: { (tap: $0, notify: $1) })
            .asObservable()
            .do {  (tap, notify)  in
                
                switch tap {
                case .close:
                    if let version = notify?.version {
                        AppSettings.showToastMgs = ToastMessageFixModel(isTap: true, versionToastNotifWebView: version, versionToastAdvancedDictionary: 0, spanDaysOfToastNotifWebView: Date().covertToDate(format: .MMddyyyy) ?? Date(), spanDaysOfToastAdvancedDictionary: nil)
                    }
                case .showRequestPrenium:
                    self.navigator.moveToPremium()
                }
            }.map({ $0.tap }).asDriverOnErrorJustComplete()
        
        let eventDismiss = input.eventDismiss.do { _ in
            self.navigator.eventDismiss()
        }
        
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .do { _ in
                self.navigator.moveToPremium()
                AppManager.shared.eventShouldAddStorePayment.onNext(false)
            }
            .asDriverOnErrorJustComplete().mapToVoid()
       
        return Output(
            getBillingInfo: getBillingInfo,
            eventTapToastView: eventTapToastView,
            getNotifyWeb: getNotifyWeb.asDriverOnErrorJustComplete(),
            eventDismiss: eventDismiss,
            showPremium: showPremium
        )
    }
}
