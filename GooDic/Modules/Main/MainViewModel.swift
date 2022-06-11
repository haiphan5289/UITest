//
//  MainViewModel.swift
//  GooDic
//
//  Created by ttvu on 6/10/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct MainViewModel {
    let useCase: MainUseCase
    let coordinator: MainNavigateProtocol
}

extension MainViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
        let clickInAppMessageButtonTrigger: Driver<String>
        let viewDidAppearTrigger: Driver<Void>
        let viewDidLayoutSubviewsTrigger: Driver<Void>
        let hideToolBarTrigger: Driver<Bool>
        let touchTrashTooltipTrigger: Driver<Void>
    }
    
    struct Output {
        let characterNumberOfDrafts: Driver<[Int]>
        let clickedButton: Driver<Void>
        let showTrashTooltip: Driver<Bool>
        let autoHideTooltips: Driver<Void>
        let checkedNewUser: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let characterNumberOfDrafts = input.loadTrigger
            .asObservable()
            .do(onNext: { _ in
                if self.useCase.isNewUser() == false {
                    self.useCase.learnedSwipeDraftTooltip()
                    self.useCase.learnedSwipeFolderTooltip()
                }
            })
            .asDriverOnErrorJustComplete()
            .withLatestFrom(self.useCase.getAllDocuments().asDriverOnErrorJustComplete())
            .map({ $0.map({ $0.content.count }) })
            
        let clickedButton = input.clickInAppMessageButtonTrigger
            .compactMap(AppURI.init(rawValue: ))
            .do(onNext: { uri in
                self.coordinator.toDynamicView(appURI: uri, entryAction: .schemeUriNormal)
            })
            .mapToVoid()
        
        // to emit a displaying tooltip event (swipe draft tooltip)
        let autoHideTrashTooltipTrigger = PublishSubject<Void>()
        
        let learnedTrashTooltip = Driver
            .merge(
                input.touchTrashTooltipTrigger,
                autoHideTrashTooltipTrigger.asDriverOnErrorJustComplete())
            .asObservable()
            .flatMapLatest(self.useCase.learnedTrashTooltip)
            .asDriverOnErrorJustComplete()

        let showTrashTooltip = Driver
            .merge(
                input.viewDidAppearTrigger,
                learnedTrashTooltip,
                input.hideToolBarTrigger.mapToVoid()
            )
            .asObservable()
            .skipUntil(input.viewDidLayoutSubviewsTrigger.asObservable())
            .asDriverOnErrorJustComplete()
            .map({ self.useCase.showTrashTooltip() })
            .withLatestFrom(input.hideToolBarTrigger, resultSelector: { (show: $0, isEditing: $1 )})
            .map({ $0.isEditing ? false : $0.show})
            .distinctUntilChanged()
        
        let autoHideTooltips = showTrashTooltip
            .filter({ $0 })
            .mapToVoid()
            .delay(.seconds(GlobalConstant.tooltipDuration))
            .do(onNext: { autoHideTrashTooltipTrigger.onNext(()) })
        
        let checkedNewUser = Driver
            .combineLatest(characterNumberOfDrafts, input.viewDidAppearTrigger)
            .mapToVoid()
        
        return Output(
            characterNumberOfDrafts: characterNumberOfDrafts,
            clickedButton: clickedButton,
            showTrashTooltip: showTrashTooltip,
            autoHideTooltips: autoHideTooltips,
            checkedNewUser: checkedNewUser
        )
    }
}
