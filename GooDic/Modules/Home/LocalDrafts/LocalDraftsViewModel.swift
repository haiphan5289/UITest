//
//  LocalDraftsViewModel.swift
//  GooDic
//
//  Created by ttvu on 12/16/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

struct LocalDraftsViewModel {
    var navigator: LocalDraftsNavigateProtocol
    var useCase: LocalDraftsUseCaseProtocol
    var folderId: FolderId
    var title: String?
    var dataSource: DraftDataSourceProxy!
    var folder: Folder?
    
    init(navigator: LocalDraftsNavigateProtocol,
         useCase: LocalDraftsUseCaseProtocol,
         folderId: FolderId = .none,
         title: String? = L10n.Draft.title,
         folder: Folder?) {
        self.navigator = navigator
        self.useCase = useCase
        self.folderId = folderId
        self.title = title
        self.folder = folder
        self.dataSource = DraftDataSourceProxy(fetchedResultsController: useCase.fetchedResultsController, folder: folder, folderId: folderId)
    }
    
//    func setResultsControllerDelegate(frcDelegate: NSFetchedResultsControllerDelegate) {
//        useCase.fetchedResultsController.delegate = frcDelegate
//        do {
//            try useCase.fetchedResultsController.performFetch()
//        } catch {
//            print("Fetch failed")
//        }
//    }
//
//    func numberOfSections() -> Int {
//        return 1
//    }
//
//    func numberOfRows(in section: Int) -> Int {
//        return useCase.fetchedResultsController.sections?[section].numberOfObjects ?? 0
//    }
//
//    func data(at indexPath: IndexPath) -> Document {
//        useCase.fetchedResultsController.object(at: indexPath).document
//    }
}

extension LocalDraftsViewModel: ViewModelProtocol, MultiSelectionFeature {
    struct Input {
        let loadDataTrigger: Driver<Void>
        let updateUITrigger: Driver<Void>
        let viewDidAppearTrigger: Driver<Void>
        let viewDidLayoutSubviewsTrigger: Driver<Void>
        let selectDraftTrigger: Driver<IndexPath>
        let deselectDraftTrigger: Driver<IndexPath>
        let selectOrDeselectAllDraftsTrigger: Driver<Void>
        let moveDraftToFolderTrigger: Driver<IndexPath>
        let binDraftTrigger: Driver<IndexPath>
        let moveSelectedDraftsTrigger: Driver<Void>
        let binSelectedDraftsTrigger: Driver<Void>
        let editingModeTrigger: Driver<Bool>
        let touchSwipeDocumentTooltipTrigger: Driver<Void>
        let checkedNewUserTrigger: Driver<Bool>
        let moveToSort: Driver<Void>
        let updateFolder: Driver<(NSFetchedResultsChangeType, IndexPath?)>
        let saveIndex: Driver<SortModel>
        let viewWillDisAppear: Driver<Void>
    }
    
    struct Output {
        let openedDraft: Driver<IndexPath>
        let binDrafts: Driver<Void>
        let movedDraftsToFolder: Driver<Void>
        let hasData: Driver<Bool>
        let realDataCount: Driver<Int>
        let showSwipeDocumentTooltip: Driver<Bool>
        let emptyViewModel: Driver<EmptyType>
        let title: Driver<String>
        let updateSelectedType: Driver<MultiSelectionType>
        let selectedDrafts: Driver<[IndexPath]>
        let autoHideToolTips: Driver<Void>
        let loading: Driver<Bool>
        let moveToSort: Driver<Void>
        let updateSort: Driver<SortModel>
        let updateFolder: Driver<Void>
        let updateFolderCoreData: Driver<Void>
        let hideButton: Driver<Bool>
        let folderStream: Driver<FolderId>
        let saveTypeDraft: Driver<SavingType>
    }
    
    func transform(_ input: Input) -> Output {
        let folderStream = input.loadDataTrigger
            .map({ folderId })
        
        let selectSingleDraft = input.selectDraftTrigger
            .withLatestFrom(input.editingModeTrigger, resultSelector: { (indexPath: $0, isEditing: $1) })
        
        let deselectSingleDraft = input.deselectDraftTrigger
            .withLatestFrom(input.editingModeTrigger, resultSelector: { (indexPath: $0, isEditing: $1) })
            
        let openedDraft = selectSingleDraft
            .filter({ $0.isEditing == false })
            .map({ $0.indexPath })
            .do(onNext: { indexPath in
                let document = self.dataSource.drafts[indexPath.row].document
                self.navigator.toDocument(document)
            })
            .asDriver()
        
        let title = input.loadDataTrigger
            .map({ return self.title ?? L10n.Draft.title })
        
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
            .map({ self.dataSource.drafts.count })
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
        
        let movedSelectedDrafts = Driver
            .merge(
                input.moveDraftToFolderTrigger.map({ [$0] }),
                input.moveSelectedDraftsTrigger
                    .withLatestFrom(multiSelectionOutput.selectedDrafts.asDriver()))
            .map({ (indexPaths) -> [Document] in
                indexPaths.map({ self.dataSource.drafts[$0.row].document })
            })
        
        let movedDraftsToFolder = moveDraftsFlow(selectedDrafts: movedSelectedDrafts)
        let activityIndicator: ActivityIndicator = ActivityIndicator()
        let binDrafts = Driver
            .merge(
                input.binDraftTrigger.map({ [$0] }),
                input.binSelectedDraftsTrigger
                    .withLatestFrom(multiSelectionOutput.selectedDrafts.asDriver()))
            .map ({ (indexPaths) -> [Document] in
                indexPaths.map({ self.dataSource.drafts[$0.row].document })
            })
            .flatMapLatest({
                return self.useCase.bin(documents: $0)
                    .trackActivity(activityIndicator)
                    .asDriverOnErrorJustComplete()
            })
            .mapToVoid()
        
        // auto-delete any empty draft.
        let deletedEmptyDocs = input.viewDidAppearTrigger
            .asObservable()
            .flatMapLatest({ self.useCase.deleteEmptyDocuments() })
            .asDriverOnErrorJustComplete()
        
        // to decide the table view should be displayed or not
        let hasData = Driver.merge(input.updateUITrigger, deletedEmptyDocs, input.loadDataTrigger)
            .map({ self.dataSource.drafts.count })
            .map({ $0 > 0 })
            .distinctUntilChanged()
        
        // to emit a displaying tooltip event (swipe draft tooltip)
        let autoHideSwipeDocumentTooltipTrigger = PublishSubject<Void>()
        
        let afterCheckingNewUser = input.checkedNewUserTrigger
            .asObservable()
            .delay(.microseconds(300), scheduler: MainScheduler.asyncInstance)
//            .filter({ useCase.isNewUser() == false })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let learnedSwipeDocumentTooltip = Driver
            .merge(
                input.touchSwipeDocumentTooltipTrigger,
                autoHideSwipeDocumentTooltipTrigger.asDriverOnErrorJustComplete())
            .asObservable()
            .take(1)
            .flatMapLatest(self.useCase.learnedSwipeDocumentTooltip)
            .asDriverOnErrorJustComplete()
        
        let realDataCount = Driver
            .merge(
                input.updateUITrigger,
                input.loadDataTrigger)
            .map({ self.dataSource.drafts })
            .map({ list -> Int in
                
                if list.count > 1 {
                    return list.count
                }
                
                if let firstElement = list.first {
                    return (firstElement.title?.isEmpty == false || firstElement.content?.isEmpty == false) ? 1 : 0
                }
                
                return 0
            })
            .distinctUntilChanged()
        
        let hasRealData = realDataCount.map({ $0 > 0 })
            
        let showConditionSwipeDocument = Driver.combineLatest(hasRealData, input.editingModeTrigger, resultSelector: { (hasData: $0, isEditing: $1) })
        
        let showSwipeDocumentTooltip = Driver
            .merge(
                Driver.zip(hasRealData, input.viewDidAppearTrigger).mapToVoid(),
                input.viewDidAppearTrigger,
                learnedSwipeDocumentTooltip,
                input.editingModeTrigger.mapToVoid(),
                afterCheckingNewUser)
            .asObservable()
            .skipUntil(Observable
                        .combineLatest(
                            input.checkedNewUserTrigger.asObservable(),
                            input.viewDidLayoutSubviewsTrigger.asObservable()))
            .map({ self.useCase.showSwipeActionInDocument() })
            .asDriverOnErrorJustComplete()
            .withLatestFrom(showConditionSwipeDocument, resultSelector: { (status: $0, hasData: $1.hasData, isEditing: $1.isEditing) })
            .map({ $0.isEditing ? false : ($0.hasData ? $0.status : false)})
            .distinctUntilChanged()
        
        let autoHideSwipeDocumentTooltip = showSwipeDocumentTooltip
            .filter({ $0 })
            .mapToVoid()
            .delay(.seconds(GlobalConstant.tooltipDuration))
            .do(onNext: { autoHideSwipeDocumentTooltipTrigger.onNext(()) })
        
        // to emit a create empty view event
        let emptyViewModel = folderStream
            .map({ folderId -> EmptyType? in
                switch folderId {
                case .none:
                    return .noDraft
                case .local(let id):
                    return id.isEmpty ? .noDraftInUncategoriedFolder : .noDraftInFolder
                case .cloud:
                    return nil
                }
            })
            .compactMap({ $0 })
        
        var sortFolderId: SortModel = SortModel.valueDefaultDraft
        
        switch self.folderId {
        case .none, .cloud: break
        case .local(let id):
            if let folder = self.folder, !id.isEmpty {
                sortFolderId = folder.getSortModel()
            }
        }
        
        let moveToSort = input.moveToSort.do { _ in
            self.navigator.moveToSort(sortModel: self.getValueSort(sortModel: sortFolderId))
        }
        
        var isActiveManual: Bool = false
        let getSortformSetting = Driver.just(self.getValueSort(sortModel: sortFolderId))
            .map { sort -> SortModel in
                switch self.folderId {
                case .none:
                    AppSettings.sortModelDrafts = SortModel(sortName: sort.sortName, asc: sort.asc, isActiveManual: isActiveManual)
                case .local(let id):
                    if id.isEmpty {
                        AppSettings.sortModelDraftsUncategorized = SortModel(sortName: sort.sortName, asc: sort.asc, isActiveManual: isActiveManual)
                    } else {
                        sortFolderId = SortModel(sortName: sort.sortName, asc: sort.asc, isActiveManual: isActiveManual)
                    }
                case .cloud: break
                }
                return self.getValueSort(sortModel: sortFolderId)
            }
        let updateSortEventToHide: PublishSubject<SortModel> = PublishSubject.init()
        var isUpdateFolder: Bool = true
        
        let updateSortfromVC = self.navigator.updateSort.asDriverOnErrorJustComplete()
            .do { sort in
                isActiveManual = true
                switch self.folderId {
                case .none:
                    AppSettings.sortModelDrafts = sort
                    
                    //refresh data
                    self.useCase.requestValue(sortModel: sort)
                    updateSortEventToHide.onNext(sort)
                    switch sort.sortName {
                    case .manual:
                        self.dataSource.checkManualIndex()
                        if AppSettings.hasSortManualHomeDrafts {
                            self.dataSource.rearrange()
                        } else {
                            AppSettings.hasSortManualHomeDrafts = true
                        }
                    default:
                        self.dataSource.sortFolder(sort: sort, isSave: false)
                    }
                case .local(let id):
                    //implement update index manual for docs
                    switch sort.sortName {
                    case .manual:
                        self.dataSource.updateSort(sort: sort)
                    case .created_at, .free, .title, .updated_at: break
                    }
                    
                    //implement update sort model for folder
                    if var folder = self.dataSource.folder, !id.isEmpty {
                        do {
                            sortFolderId = sort
                            folder.sortModelData = try sort.toData()
                            self.dataSource.folder = folder
                            self.useCase.updateSortFolder(folder: folder)
                        } catch {
                            print(error.localizedDescription)
                        }
                    } else {
                        AppSettings.sortModelDraftsUncategorized = sort
                    }
                    //refresh data
                    self.useCase.requestValue(sortModel: sort)
                    updateSortEventToHide.onNext(sort)
                    
                    if !id.isEmpty {
                        self.detectHasSortManualFolder(sort: sort)
                    } else {
                        self.detectSortManualUncategorized(sort: sort)
                    }
                    
                case .cloud: break
                }
                
            }
        
        let updateSort = Driver.merge(getSortformSetting,
                                      updateSortfromVC,
                                      input.saveIndex.do(onNext: { _ in
                                        self.dataSource.saveIndex()
                                      })
        )
        
        //This deplay will wait update Document will done, that time update folder correctly
        let updateFolder = input.updateFolder
            .filter { $0.0 == .insert || $0.0 == .move || $0.0 == .update }
            .debounce(.milliseconds(300))
            .flatMap({ _ -> Driver<Void> in
                if var folder = self.dataSource.folder {
                    let folders = AppManager.shared.folders.map { $0.folder }
                    
                    if let index = folders.firstIndex(where: { $0.id == folder.id }) {
                        folder = folders[index]
                        self.dataSource.folder = folders[index]
                    }
                    
                    print("========= \(folder.name)========== \(isUpdateFolder)")
                    if isUpdateFolder {
                        return self.useCase.updateFolder(folder: folder).asDriverOnErrorJustComplete()
                    } else {
                        isUpdateFolder = true
                        self.useCase.updateSortFolder(folder: folder)
                        return Driver.just(())
                    }
                } else {
                    return Driver.empty()
                }
            })
            .mapToVoid()
        let updateFolderCoreData = Driver.merge(self.dataSource.saveIndexFolderId.asDriverOnErrorJustComplete())
            .do { _ in
                switch self.folderId {
                case .none: break
                case .local(_):
                    isUpdateFolder = false
                    print("======= save index")
                    self.useCase.updateDocument(drafts: self.convertDocumentToIndex(docs: self.dataSource.drafts.map { $0.document }))
                case .cloud: break
                }
            }
        
        let hide = updateSortEventToHide
            .map { sort -> Bool in
                switch sort.sortName {
                case .manual: return true
                case .created_at, .free, .title, .updated_at: return false
                }
            }
            .asDriverOnErrorJustComplete()
        let show = Driver.merge(input.saveIndex.mapToVoid()).map { _ in false }
        
        let hideButton = Driver.merge(hide, show)

            
        return Output(
            openedDraft: openedDraft,
            binDrafts: binDrafts,
            movedDraftsToFolder: movedDraftsToFolder,
            hasData: hasData,
            realDataCount: realDataCount,
            showSwipeDocumentTooltip: showSwipeDocumentTooltip,
            emptyViewModel: emptyViewModel,
            title: multiSelectionOutput.title,
            updateSelectedType: multiSelectionOutput.updateSelectedType,
            selectedDrafts: multiSelectionOutput.selectedDrafts,
            autoHideToolTips: autoHideSwipeDocumentTooltip,
            loading: activityIndicator.asDriver(),
            moveToSort: moveToSort,
            updateSort: updateSort,
            updateFolder: updateFolder,
            updateFolderCoreData: updateFolderCoreData,
            hideButton: hideButton,
            folderStream: folderStream,
            saveTypeDraft: self.navigator.saveDraftType.asDriverOnErrorJustComplete()
        )
    }
    
    private func detectSortManualUncategorized(sort: SortModel) {
        switch sort.sortName {
        case .manual:
            self.dataSource.checkManualIndex()
            if AppSettings.hasSortManualUncategorized {
                self.dataSource.rearrange()
            } else {
                AppSettings.hasSortManualUncategorized = true
            }
        case .created_at, .free, .title, .updated_at:
            self.dataSource.sortFolder(sort: sort, isSave: false)
        }
    }
    
    private func detectHasSortManualFolder(sort: SortModel) {
        switch sort.sortName {
        case .manual:
            if var folder = self.dataSource.folder, let hasSortManual = folder.hasSortManual, !hasSortManual {
                folder.hasSortManual = true
                self.dataSource.folder = folder
                self.useCase.updateSortFolder(folder: folder)
            } else {
                self.dataSource.sortFolder(sort: sort, isSave: false)
            }
        default:
            self.dataSource.sortFolder(sort: sort, isSave: false)
        }
    }
    
    private func convertDocumentToIndex(docs: [Document]) -> [Document] {
        var d = docs
        
        docs.enumerated().forEach { (item) in
            let element = item.element
            let offset = item.offset
            if let index = d.firstIndex(where: { $0.id == element.id }) {
                d[index].manualIndex = docs.count - offset
            }
        }
        
        return d
    }
    
    private func getValueSort(sortModel: SortModel) -> SortModel {
        switch self.folderId {
        case .none: return AppSettings.sortModelDrafts
        case .cloud: return SortModel.valueDefaultDraft
        case .local(let id):
            if id.isEmpty {
                return AppSettings.sortModelDraftsUncategorized
            } else {
                return sortModel
            }
        }
    }
    
    private func moveDraftsFlow(selectedDrafts: Driver<[Document]>) -> Driver<Void> {
        return selectedDrafts
            .flatMap({ self.navigator.toFolderSelection(drafts: $0, draftOrigin: self.dataSource.drafts.map{ $0.document }).asDriverOnErrorJustComplete() })
            .do(onNext: { folder in
                // Navigate to the destination folder. The purpose is to display the drafts be moved to their selected folder
                self.navigator.toFolder(folder: folder)
            })
            .flatMap({ folder -> Driver<Void> in
                switch folder.id {
                case .none, .cloud: return Driver.just(())
                case .local(let id):
                    if id.isEmpty {
                        return Driver.just(())
                    } else {
                        return self.useCase.updateFolder(folder: folder).asDriverOnErrorJustComplete()
                    }
                }
            })
            .mapToVoid()
    }
}

