//
//  TrashViewModel.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

struct TrashViewModel {
    var navigator: TrashNavigateProtocol
    var useCase: TrashUseCase
    
    func setResultsControllerDelegate(frcDelegate: NSFetchedResultsControllerDelegate) {
        useCase.fetchedResultsController.delegate = frcDelegate
        do {
            try useCase.fetchedResultsController.performFetch()
        } catch {
            print("Fetch failed")
        }
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        return useCase.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func data(at indexPath: IndexPath) -> Document {
        useCase.fetchedResultsController.object(at: indexPath).document
    }
}

extension TrashViewModel: ViewModelProtocol, MultiSelectionFeature {
    struct Input {
        let loadTrigger: Driver<Void>
        let updateUITrigger: Driver<Void>
        let selectDraftTrigger: Driver<IndexPath>
        let deselectDraftTrigger: Driver<IndexPath>
        let pushBackDraftTrigger: Driver<IndexPath>
        let editingModeTrigger: Driver<Bool>
        let selectOrDeselectAllDraftsTrigger: Driver<Void>
        let deleteSelectedDraftsTrigger: Driver<Void>
        let pushBackSelectedDraftsTrigger: Driver<Void>
        let eventSelectDraftOver: Driver<Void>
    }
    
    struct Output {
        let openedDraftInReference: Driver<Void>
        let pushBackDrafts: Driver<Void>
        let deletedDrafts: Driver<Void>
        let hasData: Driver<Bool>
        let title: Driver<String>
        let updateSelectedType: Driver<MultiSelectionType>
        let hasSelectedItems: Driver<Bool>
        let loading: Driver<Bool>
        let selectedDrafts: Driver<[IndexPath]>
        let eventSelectDraftOver: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let activityIndicator: ActivityIndicator = ActivityIndicator()

        let selectSingleDraft = input.selectDraftTrigger
            .withLatestFrom(input.editingModeTrigger, resultSelector: { (indexPath: $0, isEditing: $1) })
        
        let deselectSingleDraft = input.deselectDraftTrigger
            .withLatestFrom(input.editingModeTrigger, resultSelector: { (indexPath: $0, isEditing: $1) })
        
        let openedDraftInReference = selectSingleDraft
            .filter({ $0.isEditing == false })
            .map({ $0.indexPath })
            .map({ self.data(at: $0) })
            .do(onNext: self.navigator.toReferenceView )
            .mapToVoid()
        
        let title = input.loadTrigger
            .map({ return L10n.Trash.title })
        
        let selectOrDeselectInEditMode = Driver
            .merge(
                selectSingleDraft
                    .filter({ $0.isEditing })
                    .map({ $0.indexPath }),
                deselectSingleDraft
                    .filter({ $0.isEditing })
                    .map({ $0.indexPath }))
        
        let draftsCount = Driver
            .merge(
                input.selectOrDeselectAllDraftsTrigger,
                selectOrDeselectInEditMode.mapToVoid(),
                input.updateUITrigger)
            .map({ self.useCase.fetchedResultsController.fetchedObjects?.count ?? 0 })
            .startWith(0)
            .distinctUntilChanged()
        
        let multiSelectionInput = MultiSelectionInput(
            title: title,
            editingModeTrigger: input.editingModeTrigger,
            selectOrDeselectAllDraftsTrigger: input.selectOrDeselectAllDraftsTrigger,
            selectOrDeselectInEditMode: selectOrDeselectInEditMode,
            draftsCount: draftsCount,
            reset: Driver.empty())
        
        let multiSelectionOutput = transform(multiSelectionInput)
        
        let pushBackDrafts = Driver
            .merge(
                input.pushBackDraftTrigger.map({ [$0] }),
                input.pushBackSelectedDraftsTrigger
                    .withLatestFrom(multiSelectionOutput.selectedDrafts.asDriver()))
            .map({ $0.map({ self.data(at: $0) }) })
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest({
                            self.useCase.pushBack(documents: $0)
                                .trackActivity(activityIndicator)
                                .asDriverOnErrorJustComplete()
            }).asDriverOnErrorJustComplete()
        
        let deleteDrafts = input.deleteSelectedDraftsTrigger
            .asObservable()
            .flatMap({ _ -> Observable<Bool> in
                self.navigator.toDeleteConfirmationDialog()
            })
            .filter({$0})
            .withLatestFrom(multiSelectionOutput.selectedDrafts.asDriver())
            .map({ $0.map({ self.data(at: $0) }) })
            
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest({ self.useCase.delete(documents: $0)
                            .trackActivity(activityIndicator)
                            .asDriverOnErrorJustComplete() }
            ).asDriverOnErrorJustComplete()
            
        let hasData = Driver.merge(input.updateUITrigger, input.loadTrigger)
            .map({ self.useCase.fetchedResultsController.fetchedObjects?.count ?? 0 })
            .map({ $0 > 0 ? true : false })
            .distinctUntilChanged()
        
        // to emit an event to disable or enable the related buttons
        let hasSelectedItems = multiSelectionOutput
            .selectedDrafts
            .map({ $0.count > 0 })
        
        let eventSelectDraftOver = input.eventSelectDraftOver
            .flatMap{ self.navigator
                .showMessage(L10n.Home.Selectdraft.over)
                .asDriverOnErrorJustComplete() }
        
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .do { _ in
                if AppManager.shared.getCurrentScene() == .trash {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                }
            }
            .asDriverOnErrorJustComplete().mapToVoid()
        
        return Output(
            openedDraftInReference: openedDraftInReference,
            pushBackDrafts: pushBackDrafts,
            deletedDrafts: deleteDrafts,
            hasData: hasData,
            title: multiSelectionOutput.title,
            updateSelectedType: multiSelectionOutput.updateSelectedType,
            hasSelectedItems: hasSelectedItems,
            loading: activityIndicator.asDriver(),
            selectedDrafts: multiSelectionOutput.selectedDrafts,
            eventSelectDraftOver: eventSelectDraftOver,
            showPremium: showPremium
        )
    }
}

