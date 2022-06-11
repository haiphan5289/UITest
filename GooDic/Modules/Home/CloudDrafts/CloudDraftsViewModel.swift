//
//  CloudDraftsViewModel.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

struct CloudDraftsViewModel {
    var navigator: CloudDraftsNavigateProtocol
    var useCase: CloudDraftsUseCaseProtocol
    var folder: Folder?
    
    init(navigator: CloudDraftsNavigateProtocol, useCase: CloudDraftsUseCaseProtocol, folder: Folder?) {
        self.navigator = navigator
        self.useCase = useCase
        self.folder = folder
    }
}

extension CloudDraftsViewModel: ViewModelProtocol, MultiSelectionFeature, PagingFeature {
    struct Input {
        let userInfo: Driver<UserInfo?>
        // Paging
        let loadDataTrigger: Driver<Void>
        let refreshTrigger: Driver<Void>
        let loadMoreTrigger: Driver<Void>
        let viewWillAppear: Driver<Void>
        let viewDidAppear: Driver<Void>
        let viewDidDisappear: Driver<Void>
        let viewWillDisappear: Driver<Void>
        
        // single draft
        let selectDraftTrigger: Driver<IndexPath>
        let deselectDraftTrigger: Driver<IndexPath>
        let moveDraftToFolderTrigger: Driver<IndexPath>
        let binDraftTrigger: Driver<IndexPath>
        
        // multi-selection drafts
        let editingModeTrigger: Driver<Bool>
        let selectOrDeselectAllDraftsTrigger: Driver<Void>
        let moveSelectedDraftsTrigger: Driver<Void>
        let binSelectedDraftsTrigger: Driver<Void>
        
        // tooltip
        let viewDidAppearTrigger: Driver<Void>
        let viewDidLayoutSubviewsTrigger: Driver<Void>
        let touchSwipeDocumentTooltipTrigger: Driver<Void>
        let checkedNewUserTrigger: Driver<Bool>
        let moveToSort: Driver<Void>
        let saveIndex: Driver<(SortModel, [Document])>
    }
    
    struct Output {
        // paging
        let error: Driver<Void>
        let isLoading: Driver<Bool>
        let isReloading: Driver<Bool>
        let isLoadingMore: Driver<Bool>
        
        // data
        let emptyViewModel: Driver<EmptyType>
        let folder: Driver<Folder?>
        let drafts: Driver<[Document]>
        let totalDraft: Driver<Int>
        let hasChangedTitle: Driver<String>
        
        // single draft
        let openedDraft: Driver<Void>
        let showLoading: Driver<Bool>
        
        // multi-selection drafts
        let updateSelectedType: Driver<MultiSelectionType>
        let selectedDrafts: Driver<[IndexPath]>
        let binDrafts: Driver<Void>
        let movedDraftsToFolder: Driver<Void>
        let showSwipeDocumentTooltip: Driver<Bool>
        let autoHideToolTips: Driver<Void>
        
        let screenState: Driver<CloudScreenState>
        
        // Banner
        let showBanner: Driver<BannerType>
        let moveToSort: Driver<Void>
        let sortUpdateEvent: Driver<SortModel>
        let updateSort: Driver<SortModel>
        let errorDraftSettings: Driver<Void>
        let hideButton: Driver<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        
        let onScreen = Driver
            .merge(
                input.viewDidAppear.map({ true }),
                input.viewDidDisappear.map({ false }))
        
        let showNetworkErrorScreen = BehaviorSubject<Bool?>(value: nil)
        
        let folderStream = input.loadDataTrigger
            .map({ self.folder })
        
        let title = BehaviorSubject<String>(value: self.folder?.name ?? L10n.Folder.uncategorized)
        
        // should update cloud data if users have updated data
        let changedData = NotificationCenter.default.rx
            .notification(.didUpdateCloudDrafts)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let retryLoadData = BehaviorRelay<Int>(value: 0)
        
        let loadTrigger = Driver
            .merge(
                input.loadDataTrigger,
                changedData,
                navigator.reloadCloudDraftsTrigger.asDriverOnErrorJustComplete(),
                input.userInfo
                    .map({ $0?.deviceStatus })
                    .distinctUntilChanged()
                    .mapToVoid()
                    .asObservable()
                    .skipUntil(input.viewDidAppear.asObservable())
                    .asDriverOnErrorJustComplete())
            .map({ ScreenLoadingType.loading })
        
        let refreshTrigger = input.refreshTrigger.map({ ScreenLoadingType.reloading })
        
        var sortedAtValue: String = ""
        var isReloadSortedAt: Bool = false
        let loadMoreTrigger = input.loadMoreTrigger.map({ ScreenLoadingType.loadMore })
        var sortModel: SortModel = SortModel.valueDefaultDraft
        let reSortUpdateName: PublishSubject<ScreenLoadingType> = PublishSubject.init()
        let getSort: BehaviorRelay<SortModel> = BehaviorRelay.init(value: SortModel.valueDefaultDraft)
        var isActiveManual: Bool = false
        let errorTrackerWebSetting = ErrorTracker()
        let retryWebSetting: BehaviorRelay<Int> = BehaviorRelay.init(value: 0)
        let webSettingNotFound: PublishSubject<ScreenLoadingType> = PublishSubject.init()
        let reloadSortedAtEvent: PublishSubject<Void> = PublishSubject.init()
        let reloadAfterSortedAtManual: PublishSubject<ScreenLoadingType> = PublishSubject.init()
        
        let getSortApi = Driver.merge(loadTrigger,
                                      refreshTrigger,
                                      retryWebSetting.asDriverOnErrorJustComplete().filter { $0 > 0 }.flatMap { _ in Driver.just(ScreenLoadingType.loading)},
                                      reloadAfterSortedAtManual.asDriverOnErrorJustComplete()
        )
        .flatMap({ screen in
            return useCase.hasLoggedin()
                .flatMap ({ (loggedIn) -> Observable<ScreenLoadingType> in
                    if loggedIn {
         
                        return Observable.just(screen)
                    }
                    
                    showNetworkErrorScreen.onNext(false)
                    return Observable.empty()
                }).asDriverOnErrorJustComplete()
        })
            .flatMap({ screen -> Driver<ScreenLoadingType> in
                return self.useCase.getDraftSettings(settingKey: SortVM.openfromScreen.draftsCloud.textParam, folderId: AppManager.shared.getFolderId(folder: self.folder))
                    .trackError(errorTrackerWebSetting)
                    .asDriverOnErrorJustComplete()
                    .flatMap { value -> Driver<ScreenLoadingType> in
                    sortModel = AppManager.shared.detectSortModel(value: value, isActiveManual: isActiveManual)
                    getSort.accept(sortModel)
                    return Driver.just(screen)
                }
            })
        
        let userAction = Driver.merge(getSortApi,
                                      loadMoreTrigger,
                                      reSortUpdateName.asDriverOnErrorJustComplete(),
                                      webSettingNotFound.asDriverOnErrorJustComplete())
            .filter({ _ in AppSettings.userInfo?.deviceStatus != DeviceStatus.unregistered })
            .do(onNext: { _ in
                retryLoadData.accept(0)
                retryWebSetting.accept(0)
            })
        
        let retryAction = retryLoadData.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let getPageResult = getPage(loadType: userAction,
                                    retry: retryAction,
                                    getItems: { offset -> Observable<PagingInfo<Document>> in
                                        let realOffset = offset == 0 ? 1 : offset
                                        let request: Observable<PagingInfo<Document>>
                                        if self.folder == nil {
                                            request = useCase.fetchDrafts(query: .all,
                                                                          offset: realOffset,
                                                                          limit: GlobalConstant.limitItemPerPage,
                                                                          sort: sortModel)
                                                .map({ page -> PagingInfo<Document> in
                                                    DispatchQueue.main.async {
                                                        sortedAtValue = page.sortedAt
                                                        if isReloadSortedAt {
                                                            reloadSortedAtEvent.onNext(())
                                                        }
                                                    }
                                                    return page
                                                })
                                        } else if let folderId = self.folder?.id.cloudID {
                                            request = useCase.fetchDrafts(query: .folderId(folderId),
                                                                          offset: realOffset,
                                                                          limit: GlobalConstant.limitItemPerPage,
                                                                          sort: sortModel)
                                                .map({ page -> PagingInfo<Document> in
                                                    DispatchQueue.main.async {
                                                        sortedAtValue = page.sortedAt
                                                        if isReloadSortedAt {
                                                            reloadSortedAtEvent.onNext(())
                                                        }
                                                    }
                                                    return page
                                                })
                                        } else {
                                            request = useCase.fetchDrafts(query: .uncategoried,
                                                                          offset: realOffset ,
                                                                          limit: GlobalConstant.limitItemPerPage,
                                                                          sort: sortModel)
                                                .map({ page -> PagingInfo<Document> in
                                                    DispatchQueue.main.async {
                                                        sortedAtValue = page.sortedAt
                                                        if isReloadSortedAt {
                                                            reloadSortedAtEvent.onNext(())
                                                        }
                                                    }
                                                    return page
                                                })
                                        }
                                        
                                        return useCase.hasLoggedin()
                                            .flatMap({ (loggedIn) -> Observable<PagingInfo<Document>> in
                                                if loggedIn {
                                                    return request
                                                }
                                                AppManager.shared.userInfo.accept(nil)
                                                showNetworkErrorScreen.onNext(false)
                                                return Observable.just(PagingInfo(offset: 0,
                                                                                  limit: 0,
                                                                                  totalItems: 0,
                                                                                  hasMorePages: false,
                                                                                  items: [],
                                                                                  name: ""))
                                            })
                                            .catchError({ (error) -> Observable<PagingInfo<Document>> in
                                                if let error = error as? GooServiceError {
                                                    switch error {
                                                    case .maintenanceCannotUpdate(let data):
                                                        if let data = data as? PagingInfo<CloudDocument> {
                                                            let paging = PagingInfo(offset: data.offset,
                                                                                    limit: data.limit,
                                                                                    totalItems: data.totalItems,
                                                                                    hasMorePages: data.hasMorePages,
                                                                                    items: data.items.map({ $0.document }),
                                                                                    name: data.name)
                                                            
                                                            if folder == nil {
                                                                return Observable.just(())
                                                                    .withLatestFrom(onScreen)
                                                                    .filter({ $0 })
                                                                    .flatMap({ _ in
                                                                        self.navigator
                                                                            .showMessage(L10n.DraftsAtHome.Error.maintenanceCannotUpdate)
                                                                            .map({ paging })
                                                                    })
                                                            }
                                                            
                                                            return Observable.just(())
                                                                .withLatestFrom(onScreen)
                                                                .filter({ $0 })
                                                                .flatMap({ _ in
                                                                    self.navigator
                                                                        .showMessage(L10n.Drafts.Error.maintenanceCannotUpdate)
                                                                        .map({ paging })
                                                                })
                                                                
                                                        }
                                                    default:
                                                        break
                                                    }
                                                }
                                                
                                                return Observable.error(error)
                                            })
                                            .do(onNext: { _ in
                                                showNetworkErrorScreen.onNext(false)
                                            })
                                    })
        
        let totalDraft = BehaviorSubject<Int>(value: 0)
        
        let drafts = getPageResult.page
            .do(onNext: { page in
                if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .registered {
                    userInfo.deviceStatus = .registered
                    AppManager.shared.userInfo.accept(userInfo)
                }
                
                totalDraft.onNext(page.totalItems)
            })
            .map({ $0.items })
            
        let hasChangedTitle = getPageResult.page
            .map({ $0.name.isEmpty ? L10n.Folder.uncategorized : $0.name })
        
        let hasDataStartWithNil: Driver<Bool?> = drafts.map({ !$0.isEmpty }).startWith(nil)
        
        let errorHandler = getPageResult.error
            .withLatestFrom(onScreen, resultSelector: { (error: $0, onScreen: $1) })
            .filter({ $0.onScreen })
            .withLatestFrom(folderStream, resultSelector: { (error: $0.error, folder: $1) })
            .flatMap({ (error, folder) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    showNetworkErrorScreen.onNext(false)
                    
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate: // it's just used to remind me, the below commands are not going to run because the error has been processed.
                        if folder == nil {
                            return self.navigator
                                .showMessage(L10n.DraftsAtHome.Error.maintenanceCannotUpdate)
                                .asDriverOnErrorJustComplete()
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.maintenanceCannotUpdate)
                            .asDriverOnErrorJustComplete()
                        
                    case .folderNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.folderNotFound)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                NotificationCenter.default.post(name: .didUpdateCloudFolder, object: nil)
                                self.navigator.pop()
                            })
                        
                    case .sessionTimeOut:
                        return self.useCase
                            .refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retryLoadData.value == 0 {
                                    retryLoadData.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                        
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
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
                    .withLatestFrom(hasDataStartWithNil)
                    .do(onNext: { hasData in
                        if hasData == nil || hasData == false {
                            showNetworkErrorScreen.onNext(true)
                        }
                    })
                    .mapToVoid()
                    .asDriverOnErrorJustComplete()
            })
        
        let selectSingleIndexPath = input.selectDraftTrigger
            .withLatestFrom(input.editingModeTrigger, resultSelector: { (indexPath: $0, isEditing: $1) })

        let deselectSingleIndexPath = input.deselectDraftTrigger
            .withLatestFrom(input.editingModeTrigger, resultSelector: { (indexPath: $0, isEditing: $1) })
        
        let selectedDraft = selectSingleIndexPath
            .filter({ $0.isEditing == false })
            .map({ $0.indexPath })
            .withLatestFrom(drafts, resultSelector: { (indedPath, list) -> Document? in
                return indedPath.row < list.count ? list[indedPath.row] : nil
            })
            .compactMap({ $0 })
        
        let activityIndicator = ActivityIndicator()
        let startNewAction = PublishSubject<Void>()
        let cancelTrigger = Driver
            .merge(
                input.viewWillDisappear,
                startNewAction.asDriverOnErrorJustComplete())
        let openedDraft = draftDetailFlow(selectedDraft: selectedDraft,
                                          startNewAction: startNewAction,
                                          cancelTrigger: cancelTrigger)
        
        let selectOrDeselectInEditMode = Driver
            .merge(
                selectSingleIndexPath
                    .filter({ $0.isEditing })
                    .map({ $0.indexPath }),
                deselectSingleIndexPath
                    .filter({ $0.isEditing })
                    .map({ $0.indexPath }))
        
        let draftsCount = drafts
            .map({ $0.count })
            .distinctUntilChanged()
        
        let multiSelectionInput = MultiSelectionInput(
            title: title.asDriverOnErrorJustComplete(),
            editingModeTrigger: input.editingModeTrigger,
            selectOrDeselectAllDraftsTrigger: input.selectOrDeselectAllDraftsTrigger,
            selectOrDeselectInEditMode: selectOrDeselectInEditMode,
            draftsCount: draftsCount,
            reset: Driver.merge(loadTrigger.mapToVoid(), input.refreshTrigger).skip(1))
        
        let multiSelectionOutput = transform(multiSelectionInput)
        
        let draftsOrigin: BehaviorRelay<[Document]> = BehaviorRelay.init(value: [])
        let movedSelectedDrafts = Driver
            .merge(
                input.moveDraftToFolderTrigger.map({ [$0] }),
                input.moveSelectedDraftsTrigger
                    .withLatestFrom(multiSelectionOutput.selectedDrafts.asDriver()))
            .withLatestFrom(drafts, resultSelector: { (indexPaths: $0, list: $1) })
            .map({ item -> [Document] in
                draftsOrigin.accept(item.list)
                return self.getSelectedDrafts(selectedIndexPaths: item.indexPaths, list: item.list)
                
            })
        
        let movedDraftsToFolder = moveDraftsFlow(selectedDrafts: movedSelectedDrafts, draftOrigin: draftsOrigin.asDriverOnErrorJustComplete())
        
        let binSelectedDrafts = Driver
            .merge(
                input.binDraftTrigger.map({ [$0] }),
                input.binSelectedDraftsTrigger
                    .withLatestFrom(multiSelectionOutput.selectedDrafts.asDriver()))
            .withLatestFrom(drafts, resultSelector: { (indexPaths: $0, list: $1) })
            .map({ self.getSelectedDrafts(selectedIndexPaths: $0.indexPaths, list: $0.list) })
        
        let binDrafts = deleteDraftFlow(selectedDrafts: binSelectedDrafts,
                                        activityIndicator: activityIndicator,
                                        starNewAction: startNewAction)
        
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
        
        let hasData = draftsCount
            .map({ $0 > 0 })
            .distinctUntilChanged()
            .asDriver()
        
        let showConditionSwipeDocument = Driver.combineLatest(hasData, input.editingModeTrigger, resultSelector: { (hasData: $0, isEditing: $1) })
        
        let showSwipeDocumentTooltip = Driver
            .merge(
                Driver.zip(hasData, input.viewDidAppearTrigger).mapToVoid(),
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
            .map({ $0?.id })
            .map({ folderId -> EmptyType? in
                guard let folderId = folderId else {
                    return .noCloudDraft
                }
                
                switch folderId {
                case .none:
                    return .noCloudDraft
                case .local:
                    return nil
                case .cloud:
                    return .noDraftInFolder
                }
            })
            .compactMap({ $0 })
        
        let screenState = Driver
            .combineLatest(
                input.userInfo.asDriver(),
                showNetworkErrorScreen.asDriverOnErrorJustComplete(),
                hasDataStartWithNil)
            .map({ (userInfo, networkError, hasData) -> CloudScreenState in
                guard let userInfo = userInfo else {
                    return .notLoggedIn
                }
                
                if networkError == true {
                    return .errorNetwork
                } else if networkError == false {
                    if userInfo.deviceStatus == .unregistered {
                        return .notRegisterDevice
                    }
                    
                    if hasData == false {
                        return .empty
                    } else if hasData == true {
                        return .hasData
                    }
                    
                    // hide the empty view and show the tableview, even thought it has no at this time
                    // users can still pull to refresh if they want
                    return .hasData
                }
                
                if userInfo.deviceStatus == DeviceStatus.unregistered {
                    return .notRegisterDevice
                }
                
                return .none
            })
            .do(onNext: { state in
                if state != .hasData {
                    totalDraft.onNext(0)
                }
            })
            .distinctUntilChanged()
        
        let showBanner = input.viewWillAppear
            .map({ self.folder == nil ? BannerType.homeCloudDrafts : BannerType.cloudDrafts })
            .filter({ $0.isClosed == false })
            .asObservable()
            .take(1)
            .asDriverOnErrorJustComplete()
        
        let moveToSort = input.moveToSort.do { _ in
            self.navigator.moveToSort(sortModel: sortModel, folder: self.folder)
        }
        
        let updateSortEventToHide: PublishSubject<SortModel> = PublishSubject.init()
        let updateSort = self.navigator.updateSort.asDriverOnErrorJustComplete()
            .do { sort in
                isActiveManual = false
                sortModel = sort
                reSortUpdateName.onNext(.loading)
                updateSortEventToHide.onNext(sort)
        }
        
        let reUpdateFolders: PublishSubject<SortModel> = PublishSubject.init()
        let showButton: PublishSubject<Void> = PublishSubject.init()
        
        let sortUpdateEvent = Driver.merge(getSort.asDriverOnErrorJustComplete(),
                                           self.navigator.updateSort.asDriverOnErrorJustComplete(),
//                                           viewWillDisAppear,
                                           reUpdateFolders.asDriverOnErrorJustComplete()
        )
        
        let sortFoldersEvent = Driver.merge(reloadSortedAtEvent.asDriverOnErrorJustComplete().withLatestFrom(input.saveIndex, resultSelector: { ($1) }),
                                            input.saveIndex)
            .flatMap { (sort, draft) -> Driver<Void> in
                return self.useCase.sortDrafts(drafts: draft, sortedAt: sortedAtValue, folderId: AppManager.shared.getFolderId(folder: self.folder))
                    .trackError(errorTrackerWebSetting)
                    .asDriverOnErrorJustComplete()
                    .do { _ in
                        isReloadSortedAt = false
                        reloadAfterSortedAtManual.onNext(.loading)
                    }
                    .mapToVoid()
            }
        
        let errorDraftSettings = errorTrackerWebSetting
            .asObservable()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Error.maintenanceCannotUpdate)
                            .asDriverOnErrorJustComplete()
                    case .sessionTimeOut:
                        return self.useCase
                            .refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retryWebSetting.value == 0 {
                                    retryWebSetting.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                        
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                        
                    case .otherError(let errorCode):
                        return self.navigator
                            .showMessage(errorCode: errorCode)
                            .asDriverOnErrorJustComplete()
                    case .draftNotFound:
                        sortModel = SortModel.valueDefaultDraft
                        webSettingNotFound.onNext(.loading)
                        getSort.accept(sortModel)
                        return Driver.empty()
                    case .receiptInvalid:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Error.receiptInvalid)
                            .asDriverOnErrorJustComplete()
                    case .exclusiveDraftError:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.exclusiveError)
                            .do { isdone in
                                reUpdateFolders.onNext(SortModel(sortName: sortModel.sortName, asc: sortModel.asc, isActiveManual: false))
                                reloadAfterSortedAtManual.onNext(.loading)
                                showButton.onNext(())
                            }
                            .mapToVoid()
                            .asDriverOnErrorJustComplete()

                    default:
                        return Driver.empty()
                    }
                }
                
                return self.navigator
                    .showMessage(L10n.Server.Error.timeOut)
                    .withLatestFrom(hasDataStartWithNil)
                    .do(onNext: { hasData in
                        if hasData == nil || hasData == false {
                            showNetworkErrorScreen.onNext(true)
                        }
                    })
                    .mapToVoid()
                    .asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
        
        let hide = updateSortEventToHide
            .map { sort -> Bool in
                switch sort.sortName {
                case .manual: return true
                case .created_at, .free, .title, .updated_at: return false
                }
            }
            .asDriverOnErrorJustComplete()
        
        let show = Driver.merge(sortFoldersEvent.mapToVoid(),
                                showButton.asDriverOnErrorJustComplete(),
                                input.refreshTrigger.mapToVoid()).map { _ in false }

        let hideButton = Driver.merge(hide, show)
        
        return Output(
            error: errorHandler,
            isLoading: getPageResult.isLoading,
            isReloading: getPageResult.isReloading,
            isLoadingMore: getPageResult.isLoadingMore,
            emptyViewModel: emptyViewModel,
            folder: folderStream,
            drafts: drafts,
            totalDraft: totalDraft.asDriverOnErrorJustComplete(),
            hasChangedTitle: hasChangedTitle,
            openedDraft: openedDraft,
            showLoading: activityIndicator.asDriver(),
            updateSelectedType: multiSelectionOutput.updateSelectedType,
            selectedDrafts: multiSelectionOutput.selectedDrafts,
            binDrafts: binDrafts,
            movedDraftsToFolder: movedDraftsToFolder,
            showSwipeDocumentTooltip: showSwipeDocumentTooltip,
            autoHideToolTips: autoHideSwipeDocumentTooltip,
            screenState: screenState,
            showBanner: showBanner,
            moveToSort: moveToSort,
            sortUpdateEvent: sortUpdateEvent,
            updateSort: updateSort,
            errorDraftSettings: errorDraftSettings,
            hideButton: hideButton
        )
    }
    
    private func draftDetailFlow(selectedDraft: Driver<Document>,
                                 startNewAction: PublishSubject<Void>,
                                 cancelTrigger: Driver<Void>) -> Driver<Void> {
        let activityIndicator = ActivityIndicator()
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                            .withLatestFrom(selectedDraft)
                            .do(onNext: { _ in
                                NotificationCenter.default.post(name: .didUpdateCloudDrafts, object: nil)
                            })
                            .mapToVoid()
                        
                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate(let data):
                        // navigate to the reference screen
                        return Driver.just(data)
                            .map({ $0 as? CloudDocument })
                            .compactMap({ $0 })
                            .map({ $0.document })
                            .do(onNext: { self.navigator.toReferenceView($0) })
                            .mapToVoid()
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                            
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
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
        
        let userAction = selectedDraft.mapToVoid()
            .do(onNext: {
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let openedDraft = Driver.merge(userAction, retryAction)
            .withLatestFrom(Driver.combineLatest(selectedDraft, activityIndicator.asDriver()))
            .distinctUntilChanged({ (old, new) -> Bool in
                let isWaitingResult = new.1
                let isSameDraft = old.0.id == new.0.id
                let stop = isWaitingResult == false ? false : isSameDraft
                return stop
            })
            .map({ $0.0 })
            .do(onNext: { _ in
                startNewAction.onNext(())
            })
            .flatMapLatest({ (doc) -> Driver<Document> in
                return self.useCase.fetchDraftDetail(draft: doc)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .takeUntil(cancelTrigger.asObservable())
                    .asDriverOnErrorJustComplete()
            })
            .do(onNext: self.navigator.toDocument(_:))
            .asDriver()
            .mapToVoid()
        
        return Driver.merge(openedDraft, errorHandler)
    }
    
    private func moveDraftsFlow(selectedDrafts: Driver<[Document]>, draftOrigin: Driver<[Document]>) -> Driver<Void> {
        return selectedDrafts
            .withLatestFrom(draftOrigin, resultSelector: { (select: $0, list: $1) })
            .flatMap({ self.navigator.toFolderSelection(drafts: $0, draftOrigin: $1).asDriverOnErrorJustComplete() })
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
    
    private func deleteDraftFlow(selectedDrafts: Driver<[Document]>,
                                 activityIndicator: ActivityIndicator,
                                 starNewAction: PublishSubject<Void>) -> Driver<Void> {
        let retry = BehaviorRelay<Int>(value: 0)
        let errorTracker = ErrorTracker()
        let errorHandler = errorTracker
            .asDriver()
            .flatMap({ (error) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .terminalRegistration:
                        if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .unregistered {
                            userInfo.deviceStatus = .unregistered
                            AppManager.shared.userInfo.accept(userInfo)
                        }
                        
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                            .withLatestFrom(selectedDrafts)
                            .do(onNext: { (drafts: [Document]) in
                                NotificationCenter.default.post(name: .didUpdateCloudDrafts, object: nil)
                            })
                            .mapToVoid()
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.Drafts.Error.Delete.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .catchError({ (error) -> Observable<Void> in
                                return self.navigator
                                    .showMessage(L10n.Sdk.Error.Refresh.session)
                                    .observeOn(MainScheduler.instance)
                                    .do(onNext: self.navigator.toForceLogout)
                                    .flatMap({ Observable.empty() })
                            })
                            .do(onNext: {
                                if retry.value == 0 {
                                    retry.accept(1)
                                }
                            })
                            .asDriverOnErrorJustComplete()
                                
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
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
        
        let userAction = selectedDrafts
            .mapToVoid()
            .do(onNext: {
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let deleteDrafts = Driver.merge(userAction, retryAction)
            .withLatestFrom(selectedDrafts)
            .asObservable()
            .do(onNext: { _ in
                starNewAction.onNext(())
            })
            .flatMap({ (drafts) -> Driver<[Document]> in
                // Fetch drafts detail form cloud
                return self.useCase.fetchDraftsDetail(drafts: drafts)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .asDriverOnErrorJustComplete()
            })
            .flatMap({ (drafts) -> Driver<[Document]> in
                // Save all drafts to Trash
                return self.useCase.saveToTrash(drafts: drafts)
                    .catchError({ (error) -> Observable<Void> in
                        return self.navigator
                            .showMessage(L10n.Error.otherErrorAtLocal)
                            .flatMap({ Observable.empty() })
                    })
                    .asDriverOnErrorJustComplete()
                    .map({ _ in drafts })
            })
            .flatMap({ (drafts) -> Driver<Void> in
                // Delete drafts on Cloud
                return self.useCase.delete(documents: drafts)
                    .trackActivity(activityIndicator)
                    .do(onNext: {
                        NotificationCenter.default.post(name: .didUpdateCloudDrafts, object: nil)
                    })
                    .asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
        
        return Driver.merge(deleteDrafts, errorHandler)
    }
    
    func getSelectedDrafts(selectedIndexPaths indexPaths: [IndexPath],
                           list: [Document]) -> [Document] {
        
        let drafts = indexPaths.map { (indexPath) -> Document? in
            if indexPath.row < list.count {
                return list[indexPath.row]
            }
            
            return nil
        }
        
        return drafts.compactMap({ $0 })
    }
}
