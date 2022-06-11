//
//  HomeViewModel.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct HomeViewModel {
    var navigator: HomeNavigateProtocol
    var useCase: HomeUseCaseProtocol
}

extension HomeViewModel: ViewModelProtocol {
    struct Input {
        let loadDataTrigger: Driver<Void>
        let viewDidAppear: Driver<Void>
        let viewWillDisappear: Driver<Void>
        let isCloudTrigger: Driver<Bool>
        let openCreationTrigger: Driver<Void>
        let userInfo: Driver<UserInfo?>
        let cloudScreenState: Driver<CloudScreenState>
        
        let editingModeTrigger: Driver<Bool>
        let numberOfSelectedDrafts: Driver<Int>
        let localSelectionButtonTitle: Driver<String>
        let numberOfSelectedCloudDrafts: Driver<Int>
        let cloudSelectionButtonTitle: Driver<String>
        
        let buttonInfoBannerTrigger: Driver<Void>
        let buttonCloseBannerTrigger: Driver<Void>
        
        // tooltips
        let hasLocalData: Driver<Bool>
        let hasCloudData: Driver<Bool>
        let viewDidLayoutSubviewsTrigger: Driver<Void>
        let showedSwipeDocumentTooltip: Driver<Bool>
        let checkedNewUserTrigger: Driver<Bool>
        let touchAddNewDocumentTooltipTrigger: Driver<Void>
        let touchEditModeTooltipTrigger: Driver<Void>
        let eventSelectDraftOver: Driver<Void>
    }
    
    struct Output {
        // UI
        let title: Driver<String>
        let hideCreationButton: Driver<Bool>
        let openCreation: Driver<Void>
        let selectionButtonTitle: Driver<String> // select all / deselect all
        let enableLocalTab: Driver<Bool>
        let enableCloudTab: Driver<Bool>
        
        let titleForBanner: Driver<String?>
        let buttonInfoBannerAction: Driver<Void>
        let buttonCloseBannerAction: Driver<Void>
        
        // tooltips
        let showEditModeTooltip: Driver<Bool>
        let showAddDocumentTooltip: Driver<Bool>
        let autoHideToolTips: Driver<Void>
        
        // tracking
        let isLogin: Driver<Bool>
        let eventSelectDraftOver: Driver<Void>
        let autoCloseBannerAction: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let uriSchemeRelay: BehaviorRelay<String?> = BehaviorRelay.init(value: nil)
        let hideCreationButton = Driver
            .combineLatest(
                input.loadDataTrigger,
                input.editingModeTrigger,
                input.isCloudTrigger,
                input.userInfo,
                input.cloudScreenState)
            .map({ _, isEditMode, isCloud, userInfo, cloudScreenState -> Bool in
                if  isEditMode == true { // hide in edit mode
                    return true
                }
                
                if isCloud == false { // always show at local tab
                    return false
                }
                
                if cloudScreenState != .empty && cloudScreenState != .hasData {
                    return true
                }
                
                return !(userInfo?.deviceStatus == DeviceStatus.registered ? true : false) // show the button depend on the status linked device
            })
        
        let title = Driver
            .combineLatest(
                input.editingModeTrigger,
                input.numberOfSelectedDrafts,
                input.numberOfSelectedCloudDrafts,
                input.isCloudTrigger, resultSelector: { (isEditing: $0, numLocal: $1, numCloud: $2, isCloud: $3) })
            .map({ (data) -> String in
            if data.isEditing {
                return L10n.Draft.EditMode.title(data.isCloud ? data.numCloud : data.numLocal)
            }

                return L10n.Draft.title
        })
        
        //input Data with first, to fix bug event selectionButtonTitle
        let selectionButtonTitle = Driver
            .combineLatest(
                input.isCloudTrigger.startWith(false),
                input.localSelectionButtonTitle,
                input.cloudSelectionButtonTitle.startWith(""),
                resultSelector: {(isCloud: $0, localTitle: $1, cloudTitle: $2)})
            .map({ $0.isCloud ? $0.cloudTitle : $0.localTitle })
        
        // navigate to Creation view
        let createDraftTrigger = input.openCreationTrigger
            .withLatestFrom(input.isCloudTrigger)
        let cancelTrigger = input.viewWillDisappear
        let openCreation = showCreationDraftFlow(creationTrigger: createDraftTrigger,
                                                 cancelTrigger: cancelTrigger)
        
        let enableLocalTab = input.editingModeTrigger
            .withLatestFrom(input.hasLocalData, resultSelector: { (isEditMode: $0, hasData: $1) })
            .map({ $0.isEditMode ? $0.hasData : true })
        
        let enableCloudTab = input.editingModeTrigger
            .withLatestFrom(input.hasCloudData, resultSelector: { (isEditMode: $0, hasData: $1) })
            .map({ $0.isEditMode ? $0.hasData : true })
                    
        // to emit a displaying tooltip event (edit mode tooltip)
        let autoHideEditModeTooltipTrigger = PublishSubject<Void>()
        
        let afterCheckingNewUser = input.checkedNewUserTrigger
            .asObservable()
            .delay(.microseconds(300), scheduler: MainScheduler.asyncInstance)
            .asDriverOnErrorJustComplete()
            .mapToVoid()

        let learnedEditModelTooltip = Driver
            .merge(
                input.touchEditModeTooltipTrigger,
                input.editingModeTrigger.filter({ $0 }).mapToVoid(),
                autoHideEditModeTooltipTrigger.asDriverOnErrorJustComplete())
            .asObservable()
            .take(1)
            .flatMapLatest(self.useCase.learnedEditModeTooltip)
            .asDriverOnErrorJustComplete()
        
        let skipCondition: Observable<Void>
        let swipeValueTrigger: Driver<Bool>
        
        if useCase.showSwipeActionInDocument() {
            if useCase.isNewUser() {
                skipCondition = input.showedSwipeDocumentTooltip.filter({ $0 }).asObservable().mapToVoid()
                swipeValueTrigger = input.showedSwipeDocumentTooltip
            } else {
                skipCondition = Observable
                    .combineLatest(
                        input.checkedNewUserTrigger.asObservable(),
                        input.viewDidLayoutSubviewsTrigger.asObservable()).mapToVoid()
                swipeValueTrigger = Driver.just(false)
            }
        } else {
            skipCondition = Observable.just(())
            swipeValueTrigger = Driver.just(false)
        }
        
        
        let afterCondition = skipCondition
            .delay(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .asDriverOnErrorJustComplete()
        
        let hasData = Driver
            .merge(
                input.hasLocalData,
                input.hasCloudData)
            .mapToVoid()
        
        let showEditModeTooltip = Driver
            .merge(
                hasData,
                input.viewDidAppear,
                learnedEditModelTooltip,
                input.showedSwipeDocumentTooltip.mapToVoid(),
                afterCheckingNewUser.asDriver(),
                afterCondition,
                input.isCloudTrigger.mapToVoid())
            .asObservable()
            .skipUntil(skipCondition)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(
                Driver.combineLatest(
                    input.isCloudTrigger,
                    input.hasLocalData,
                    input.hasCloudData,
                    swipeValueTrigger,
                    resultSelector: {(isCloud: $0, localData: $1, cloudData: $2, swipeValue: $3) }))
            .flatMapLatest({ (data) -> Driver<Bool> in
                let hasData = data.isCloud ? data.cloudData : data.localData
                
                if hasData {
                    if data.swipeValue && self.useCase.showEditModeTooltip() {
                        return Driver.just(())
                            .delay(.seconds(3))
                            .map({ self.useCase.showEditModeTooltip() })
                    }
                    
                    return Driver.just(self.useCase.showEditModeTooltip())
                }
                
                return Driver.just(false)
            })
            .distinctUntilChanged()
        
        let autoHideEditModeTooltip = showEditModeTooltip
            .filter({ $0 })
            .mapToVoid()
            .delay(.seconds(GlobalConstant.tooltipDuration))
            .withLatestFrom(showEditModeTooltip.asDriver(), resultSelector: {($1)})
            .do(onNext: { show in
                if show {
                    autoHideEditModeTooltipTrigger.onNext(())
                }
            })
            .mapToVoid()
        
        // to emit a displaying tooltip event (add draft tooltip)
        let autoHideAddDocumentTooltipTrigger = PublishSubject<Void>()
        
        let learnedAddDocumentTooltip = Driver
            .merge(
                input.touchAddNewDocumentTooltipTrigger,
                openCreation,
                input.isCloudTrigger.mapToVoid().skip(1),
                autoHideAddDocumentTooltipTrigger.asDriverOnErrorJustComplete())
            .asObservable()
            .take(1)
            .flatMapLatest(self.useCase.learnedAddNewDocumentTooltip)
            .asDriverOnErrorJustComplete()
        
        let showAddDocumentTooltip = Driver
            .merge(
                input.loadDataTrigger,
                input.viewDidAppear,
                learnedAddDocumentTooltip)
            .map({ self.useCase.showAddNewDocumentTooltip() })
            .distinctUntilChanged()
        
        let autoHideAddDocumentTooltip = showAddDocumentTooltip
            .filter({ $0 })
            .mapToVoid()
            .delay(.seconds(GlobalConstant.tooltipDuration))
            .do(onNext: { autoHideAddDocumentTooltipTrigger.onNext(()) })
        
        // auto-hide event
        let autoHideToolTips = Driver
            .merge(
                autoHideAddDocumentTooltip,
                autoHideEditModeTooltip)
        
        // check login as the screen appears
        let isLogin = input.viewDidAppear
            .flatMap({ self.useCase.hasLoggedin().asDriverOnErrorJustComplete() })
        
        let eventSelectDraftOver = input.eventSelectDraftOver
            .flatMap{ self.navigator
                .showMessage(L10n.Home.Selectdraft.over)
                .asDriverOnErrorJustComplete() }
        
        let titleBannerHome = input.viewDidAppear
            .flatMap {
                self.useCase.getNotiHomeBanner().asDriverOnErrorJustComplete()
            }
            .do { noti in
                uriSchemeRelay.accept(noti?.uriScheme)
            }
            .map { $0?.titleBannerToShow() }
        
        let buttonCloseBannerAction = input.buttonCloseBannerTrigger.do { _ in
            self.useCase.userForceCloseBanner()
        }
        
        let buttonInfoBannerAction = input.buttonInfoBannerTrigger
            .do { _ in
                self.navigator.transition(uri: uriSchemeRelay.value)
        }
        
        let triggerAutoCloseBanner = titleBannerHome
            .asObservable()
            .flatMapLatest({ (title) -> Observable<Void> in
                return Observable.empty()
        })
        
        let autoCloseBannerAction = triggerAutoCloseBanner
            .takeUntil(buttonCloseBannerAction.asObservable())
            .do { _ in
                self.useCase.userForceCloseBanner()
            }.asDriverOnErrorJustComplete()
        
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .delay(.milliseconds(200), scheduler: MainScheduler.instance)
            .do { _ in
                if AppManager.shared.getCurrentScene() == .openHomeScreen {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                }
            }
            .asDriverOnErrorJustComplete().mapToVoid()

        return Output(
            title: title,
            hideCreationButton: hideCreationButton,
            openCreation: openCreation,
            selectionButtonTitle: selectionButtonTitle,
            enableLocalTab: enableLocalTab,
            enableCloudTab: enableCloudTab,
            titleForBanner: titleBannerHome,
            buttonInfoBannerAction: buttonInfoBannerAction,
            buttonCloseBannerAction: buttonCloseBannerAction,
            showEditModeTooltip: showEditModeTooltip,
            showAddDocumentTooltip: showAddDocumentTooltip,
            autoHideToolTips: autoHideToolTips,
            isLogin: isLogin,
            eventSelectDraftOver: eventSelectDraftOver,
            autoCloseBannerAction: autoCloseBannerAction,
            showPremium: showPremium
        )
    }
    
    // creationTrigger: true is cloud
    private func showCreationDraftFlow(creationTrigger: Driver<Bool>,
                                       cancelTrigger: Driver<Void>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.Home.Error.CreateDraft.maintenance)
                            .asDriverOnErrorJustComplete()
                         
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                        
                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .asDriverOnErrorJustComplete()
            })
        
        let userAction = creationTrigger
            .mapToVoid()
        
        let openCreation = userAction
            .withLatestFrom(activityIndicator)
            .filter({ $0 == false })
            .withLatestFrom(creationTrigger)
            .flatMap({ (isCloud) -> Driver<Void> in
                if isCloud {
                    return self.useCase.checkAPIStatus()
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .takeUntil(cancelTrigger.asObservable())
                        .asDriverOnErrorJustComplete()
                        .do(onNext: {
                            self.navigator.toNewDocument(with: .cloud(""), isHome: false)
                        })
                }

                return Driver.just(())
                    .do(onNext: {
                        self.navigator.toNewDocument(with: .local(""), isHome: true)
                    })
            })
        
        return Driver.merge(openCreation, errorHandler)
    }
}
