//
//  DraftsViewModel.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

struct DraftsViewModel {
    var navigator: DraftsNavigateProtocol
    var useCase: DraftsUseCaseProtocol
    var folderId: FolderId
    var rawTitle: String?
    
    init(navigator: DraftsNavigateProtocol, useCase: DraftsUseCaseProtocol, folderId: FolderId = .none, title: String? = L10n.Draft.title) {
        self.navigator = navigator
        self.useCase = useCase
        self.folderId = folderId
        self.rawTitle = title
    }
}

extension DraftsViewModel: ViewModelProtocol, MultiSelectionFeature {
    struct Input {
        let loadDataTrigger: Driver<Void>
        let openCreationTrigger: Driver<Void>
        let selectOrDeselectAllDraftsTrigger: Driver<Void>
        let editingModeTrigger: Driver<Bool>
        let numberOfSelectedDrafts: Driver<Int>
        let title: Driver<String>
        let useInfo: Driver<UserInfo?>
        let cloudScreenState: Driver<CloudScreenState>
        
        // tooltips
        let hasData: Driver<Bool>
        let viewDidAppear: Driver<Void>
        let viewWillDisappear: Driver<Void>
        let viewDidLayoutSubviewsTrigger: Driver<Void>
        let showedSwipeDocumentTooltip: Driver<Bool>
        let checkedNewUserTrigger: Driver<Bool>
        let touchAddNewDocumentTooltipTrigger: Driver<Void>
        let touchEditModeTooltipTrigger: Driver<Void>
        let eventSelectDraftOver: Driver<Void>
    }
    
    struct Output {
        let title: Driver<String>
        let isCloud: Driver<Bool>
        let hideCreationButton: Driver<Bool>
        let openCreation: Driver<Void>
        
        // tooltips
        let showEditModeTooltip: Driver<Bool>
        let showAddDocumentTooltip: Driver<Bool>
        let autoHideToolTips: Driver<Void>
        let eventSelectDraftOver: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let folderStream = input.loadDataTrigger
            .map({ folderId })
        
        let folderNameStream = input.title
            .startWith(self.rawTitle ?? L10n.Draft.title)
        
        let isCloud = folderStream
            .map({ folderId -> Bool in
                if case FolderId.cloud(_) = folderId {
                    return true
                }
                
                return false
            })
        
        let hideCreationButton = Driver
            .combineLatest(
                input.loadDataTrigger,
                input.editingModeTrigger,
                input.useInfo,
                input.cloudScreenState,
                isCloud)
            .map({ _, isEditMode, userInfo, cloudScreenState, isCloud -> Bool in
                if  isEditMode == true { // hide in edit mode
                    return true
                }
                
                if isCloud == false {
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
                folderNameStream,
                resultSelector: { (isEditing: $0, number: $1, folderName: $2) })
            .map({ (data) -> String in
                if data.isEditing {
                    return L10n.Draft.EditMode.title(data.number)
                }
                
                return data.folderName
            })
        
        // navigate to Creation view
        let startNewAction = PublishSubject<Void>()
        let cancelTrigger = Driver.merge(input.viewWillDisappear, startNewAction.asDriverOnErrorJustComplete())
        let createWithFolderIdTrigger = input.openCreationTrigger
            .withLatestFrom(folderStream)
        
        let openCreation = showCreationDraftFlow(createWithFolderIdTrigger: createWithFolderIdTrigger,
                                                 startNewAction: startNewAction,
                                                 cancelTrigger: cancelTrigger,
                                                 folderNameStream: folderNameStream)
        
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
        
        let showEditModeTooltip = Driver
            .merge(
                input.hasData.mapToVoid(),
//                Driver.zip(input.hasData, input.viewDidAppear).mapToVoid(),
                input.viewDidAppear,
                learnedEditModelTooltip,
                input.showedSwipeDocumentTooltip.mapToVoid(),
                afterCheckingNewUser.asDriver(),
                afterCondition)
            .asObservable()
            .skipUntil(skipCondition)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(
                Driver.combineLatest(
                    input.hasData,
                    swipeValueTrigger,
                    resultSelector: {(hasData: $0, swipeValue: $1)}))
            .flatMapLatest({ data -> Driver<Bool> in
                if data.hasData {
                    if data.swipeValue && self.useCase.showEditModeTooltip() {
                        return Driver.just(())
                            .delay(.seconds(3))
                            .map({self.useCase.showEditModeTooltip()})
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
            .do(onNext: { autoHideEditModeTooltipTrigger.onNext(()) })
        
        // to emit a displaying tooltip event (add draft tooltip)
        let autoHideAddDocumentTooltipTrigger = PublishSubject<Void>()
        
        let learnedAddDocumentTooltip = Driver
            .merge(
                input.touchAddNewDocumentTooltipTrigger,
                openCreation,
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
        
        // all auto-hide events
        let autoHideToolTips = Driver
            .merge(
                autoHideAddDocumentTooltip,
                autoHideEditModeTooltip)
        
        let eventSelectDraftOver = input.eventSelectDraftOver
            .flatMap{ self.navigator
                .showMessage(L10n.Home.Selectdraft.over)
                .asDriverOnErrorJustComplete() }
        
        return Output(
            title: title,
            isCloud: isCloud,
            hideCreationButton: hideCreationButton,
            openCreation: openCreation,
            showEditModeTooltip: showEditModeTooltip,
            showAddDocumentTooltip: showAddDocumentTooltip,
            autoHideToolTips: autoHideToolTips,
            eventSelectDraftOver: eventSelectDraftOver
        )
    }
    
    private func showCreationDraftFlow(createWithFolderIdTrigger: Driver<FolderId>,
                                       startNewAction: PublishSubject<Void>,
                                       cancelTrigger: Driver<Void>,
                                       folderNameStream: Driver<String>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.CreateDraft.maintenance)
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
        
        let userAction = createWithFolderIdTrigger
            .mapToVoid()
        
        let openCreation = userAction
            .withLatestFrom(activityIndicator)
            .filter({ $0 == false })
            .withLatestFrom(createWithFolderIdTrigger)
            .flatMap({ (folderId) -> Driver<FolderId> in
                if case .cloud(_) = folderId {
                    return self.useCase.checkAPIStatus()
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .takeUntil(cancelTrigger.asObservable())
                        .asDriverOnErrorJustComplete()
                        .map({ folderId })
                }

                return Driver.just(folderId)
            })
            .withLatestFrom(folderNameStream, resultSelector: { (folderId: $0, folderName: $1) })
            .do(afterNext: { (folderId, folderName) in
                let folder = self.useCase.getFolder(folderName: folderName)
                self.navigator.toNewDocument(with: folderId, folder: folder)
            })
            .mapToVoid()
        
        return Driver.merge(openCreation, errorHandler)
    }
}
