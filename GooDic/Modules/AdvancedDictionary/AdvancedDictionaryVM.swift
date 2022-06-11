//
//  AdvancedDictionaryVM.swift
//  GooDic
//
//  Created by haiphan on 10/11/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct AdvancedDictionaryVM {
    var navigator: AdvancedDictionaryNavigateProtocol
    var useCase: AdvancedDictionaryUseCaseProtocol
    private let disposeBag = DisposeBag()
}

struct TrackingExecSearchData {
    var word: String
    var kind: GATracking.ExecSearchKind
    var condition: GATracking.SearchCondition
}

extension AdvancedDictionaryVM: ViewModelProtocol {
    struct Input {
        let action: Driver<AdvancedDictionaryVC.Action>
        let getNotifyDictionaryTrigger: Driver<Void>
        let eventTapToastView: Driver<ToastMessageFixView.TapAction>
        let textTrigger: Driver<String>
        let statusSearchTrigger: Driver<AdvancedDictionaryVC.StatusStackView>
        let searchInputTrigger: Driver<Void>
        let selectedItem: Driver<Int>
    }
    
    struct Output {
        let action: Driver<Void>
        let keyboardHeight: Driver<PresentAnim>
        let getBillingInfo: Driver<BillingInfo>
        let getNotifyDictionary: Driver<NotiWebModel?>
        let eventTapToastView: Driver<ToastMessageFixView.TapAction>
        let showSuggestion: Driver<[String]>
        let errorHandler: Driver<Void>
        let showNetworkAction: Driver<Void>
        let showResult: Driver<Void>
        let trackingExecSearchData: Driver<TrackingExecSearchData>
        let eventDismiss: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let trackingExecSearchData = PublishSubject<TrackingExecSearchData>()
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        let handleErrorNetwork = PublishSubject<Void>()
        let showNetworkAction = handleErrorNetwork
            .flatMap({
                self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let action = input.action
            .do { action in
                self.navigator.dismissView(action: action)
            }
            .mapToVoid()

        let keyboardHeight = keyboardHandle()
            .asDriverOnErrorJustComplete()
        
        let getBillingInfo = AppManager.shared.billingInfo
            .asDriverOnErrorJustComplete()
        
        let resultNotifyDictionary =  PublishSubject<NotiWebModel?>.init()
        let getNotifyDictionary = input.getNotifyDictionaryTrigger
            .asObservable()
            .flatMap({
                self.useCase.notifyDictionary()
            })
            .do { notifModel  in
                resultNotifyDictionary.onNext(notifModel)
            }
        
        let eventTapToastView = input.eventTapToastView
            .asObservable()
            .withLatestFrom(resultNotifyDictionary.asObservable().asDriverOnErrorJustComplete(), resultSelector: { (tap: $0, notify: $1) })
            .asObservable()
            .do {  (tap, notify) in
                
                switch tap {
                case .close:
                    if let version = notify?.version {
                        AppSettings.showToastMgsDictionary = ToastMessageFixModel(isTap: true, versionToastNotifWebView: 0, versionToastAdvancedDictionary: version, spanDaysOfToastNotifWebView: nil, spanDaysOfToastAdvancedDictionary: Date().covertToDate(format: .MMddyyyy) ?? Date())
                    }
                case .showRequestPrenium:
                    self.navigator.moveToPremium()
                }
            }.map({ $0.tap }).asDriverOnErrorJustComplete()
        
        let status = input.statusSearchTrigger
        
        let inputTrigger = input.textTrigger.debounce(.milliseconds(300))
            .distinctUntilChanged()
        
        let suggestionsStream = Driver.combineLatest(status, inputTrigger)
            .flatMap { (status, text) -> Driver<[String]> in
                
                if status != .prefix && status != .exact {
                    return Driver.just([])
                }
                
                if text.isEmpty  {
                    return Driver.just([])
                }
                
                return self.useCase
                    .suggest(text: text)
                    .trackError(errorTracker)
                    .asDriverOnErrorJustComplete()
            }
        
        let searchInputTrigger = input.searchInputTrigger.withLatestFrom(input.textTrigger)
            .do(onNext: { (result) in
                trackingExecSearchData.onNext(TrackingExecSearchData(word: result, kind: .inputWord, condition: .prefixMatch))
            })
                
        let selectedItem = input.selectedItem.withLatestFrom(suggestionsStream, resultSelector: { (selectedIndex, list) -> String in
            if selectedIndex < list.count {
                return list[selectedIndex]
            }
            return ""
        }).do(onNext: { (result) in
            trackingExecSearchData.onNext(TrackingExecSearchData(word: result, kind: .suggestedWord, condition: .prefixMatch))
        })
        
        let searchString = Driver
            .merge(
                searchInputTrigger,
                selectedItem
            )
    
        let showResult = searchString
            .filter({ $0.count > 0 })
            .withLatestFrom(input.statusSearchTrigger, resultSelector: { (text: $0, status: $1) })
            .flatMapLatest({ self.useCase.search(text: $0, type: $1.model).asDriverOnErrorJustComplete()})
            .do(onNext: { (result) in
                if AppManager.shared.isConnected == false {
                    handleErrorNetwork.onNext(())
                } else {
                    self.navigator.toResultWebView(url: result)
                }
            })
            .mapToVoid()
        
        let showSuggestion = Driver.merge(suggestionsStream)
        
        let eventDismiss = self.navigator.eventDismisss().asDriverOnErrorJustComplete()
                
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .do { _ in
                self.navigator.moveToPremium()
                AppManager.shared.eventShouldAddStorePayment.onNext(false)
            }
            .asDriverOnErrorJustComplete().mapToVoid()
        
        return Output(
            action: action,
            keyboardHeight: keyboardHeight,
            getBillingInfo: getBillingInfo,
            getNotifyDictionary: getNotifyDictionary.asDriverOnErrorJustComplete(),
            eventTapToastView: eventTapToastView,
            showSuggestion: showSuggestion,
            errorHandler: errorHandler,
            showNetworkAction: showNetworkAction,
            showResult: showResult,
            trackingExecSearchData: trackingExecSearchData.asDriverOnErrorJustComplete(),
            eventDismiss: eventDismiss,
            showPremium: showPremium
        )
    }
}
