//
//  DictionaryViewModel.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct DictionaryViewModel {
    let navigator: DictionaryNavigateProtocol
    let useCase: DictionaryUseCaseProtocol
    
    init(navigator: DictionaryNavigateProtocol, useCase: DictionaryUseCaseProtocol) {
        self.navigator = navigator
        self.useCase = useCase
    }
}

extension DictionaryViewModel: ViewModelProtocol {
    struct Input {
        let textTrigger: Driver<String>
        let searchInputTrigger: Driver<Void>
        let selectedItem: Driver<Int>
        let moveToAdvanced: Driver<Void>
    }
    
    struct Output {
        let showResult: Driver<Void>
        let searchString: Driver<String>
        let showSuggestion: Driver<[String]>
        let keyboardHeight: Driver<PresentAnim>
        let errorHandler: Driver<Void>
        let showNetworkAction: Driver<Void>
        let moveToAdvanced: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        let suggestionsStream = input.textTrigger
            .throttle(.milliseconds(300))
            .distinctUntilChanged()
            .flatMapLatest ({ (text) -> Driver<[String]> in
                if text.isEmpty { return Driver.just([]) }
                
                return self.useCase
                    .suggest(text: text)
                    .trackError(errorTracker)
                    .asDriverOnErrorJustComplete()
            })
        
        let searchString = Driver
            .merge(
                input.searchInputTrigger.withLatestFrom(input.textTrigger),
                input.selectedItem.withLatestFrom(suggestionsStream, resultSelector: { (selectedIndex, list) -> String in
                    if selectedIndex < list.count {
                        return list[selectedIndex]
                    }
                    return ""
            }))
        
        let handleErrorNetwork = PublishSubject<Void>()
        let showNetworkAction = handleErrorNetwork
            .flatMap({
                self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let showResult = searchString
            .filter({ $0.count > 0 })
            .flatMapLatest({ self.useCase.search(text: $0).asDriverOnErrorJustComplete()})
            .do(onNext: { (result) in
                if AppManager.shared.isConnected == false {
                    handleErrorNetwork.onNext(())
                } else {
                    self.navigator.toResultWebView(url: result)
                }
            })
            .mapToVoid()
        
        let showSuggestion = Driver.merge(suggestionsStream, showResult.map({[]}))
        
        let keyboardHeight = keyboardHandle()
            .asDriverOnErrorJustComplete()
        
        let moveToAdvanced = input.moveToAdvanced
            .do { _ in self.navigator.toAdvanced() }
        
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .do { _ in
                if AppManager.shared.getCurrentScene() == .search {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                }
            }
            .asDriverOnErrorJustComplete().mapToVoid()
        
        return Output(
            showResult: showResult,
            searchString: searchString,
            showSuggestion: showSuggestion,
            keyboardHeight: keyboardHeight,
            errorHandler: errorHandler,
            showNetworkAction: showNetworkAction,
            moveToAdvanced: moveToAdvanced,
            showPremium: showPremium
        )
    }
}
