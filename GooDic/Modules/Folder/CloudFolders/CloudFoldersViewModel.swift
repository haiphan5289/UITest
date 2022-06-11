//
//  CloudFoldersViewModel.swift
//  GooDic
//
//  Created by ttvu on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct CloudFoldersViewModel: ViewModelProtocol {
    let useCase: CloudFoldersUseCaseProtocol
    let navigator: CloudFoldersNavigateProtocol
    let hideButtonCreate: PublishSubject<Bool> = PublishSubject.init()
}

extension CloudFoldersViewModel: PagingFeature {
    struct Input {
        let userInfo: Driver<UserInfo?>
        let loadDataTrigger: Driver<Void>
        let refreshTrigger: Driver<Void>
        let loadMoreTrigger: Driver<Void>
        let viewWillAppear: Driver<Void>
        let viewDidAppear: Driver<Void>
        let viewDidDisappear: Driver<Void>
        let viewWillDisappear: Driver<Void>
        let renameAtIndexPath: Driver<IndexPath>
        let deleteAtIndexPath: Driver<IndexPath>
        let selectAtIndexPath: Driver<IndexPath>
        let forceReload: Driver<Void>
        let moveToSort: Driver<Void>
        let saveIndex: Driver<(SortModel, [Folder])>
    }
    
    struct Output {
        // paging
        let error: Driver<Void>
        let isLoading: Driver<Bool>
        let isReloading: Driver<Bool>
        
        // data
        let folders: Driver<[Folder]>
        let movedToFolder: Driver<Folder>
        let renamedFolder: Driver<Void>
        let deletedFolder: Driver<Void>
        let loading: Driver<Bool>
        let screenState: Driver<CloudScreenState>
        
        // banner
        let showBanner: Driver<BannerType>
        let moveToSort: Driver<Void>
        let updateSort: Driver<SortModel>
        let sortUpdateEvent: Driver<SortModel>
        let errorWebSettings: Driver<Void>
        let hideButton: Driver<Bool>
        let reUpdateFolders: Driver<Void>
//        let sortAtEvent: Driver<Void>
//        let reloadSortedAtFlow: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let showNetworkErrorScreen = BehaviorSubject<Bool?>(value: nil)
        
        let onScreen = Driver
            .merge(
                input.viewDidAppear.map({ true }),
                input.viewDidDisappear.map({ false }))
        
        let retryLoadData = BehaviorRelay<Int>(value: 0)
        
        let loadTrigger = Driver
            .merge(
                input.loadDataTrigger,
                input.forceReload,
                input.userInfo.map({ $0?.deviceStatus })
                    .distinctUntilChanged()
                    .mapToVoid()
                    .asObservable()
                    .skipUntil(input.viewDidAppear.asObservable())
                    .asDriverOnErrorJustComplete())
            .map({ ScreenLoadingType.loading })
        
        let errorTrackerWebSetting = ErrorTracker()
        let refreshTrigger = input.refreshTrigger.map({ ScreenLoadingType.reloading })
        let loadMoreTrigger = input.loadMoreTrigger.map({ ScreenLoadingType.loadMore })
        let reSortUpdateName: PublishSubject<ScreenLoadingType> = PublishSubject.init()
        let reloadAfterSortedAtManual: PublishSubject<ScreenLoadingType> = PublishSubject.init()
        let retryWebSetting: BehaviorRelay<Int> = BehaviorRelay.init(value: 0)
        let webSettingNotFound: PublishSubject<ScreenLoadingType> = PublishSubject.init()
        
        let activityIndicator = ActivityIndicator()
        let getSort: BehaviorRelay<SortModel> = BehaviorRelay.init(value: SortModel.valueDefault)
        var sortModel: SortModel = SortModel.valueDefault
        var isActiveManual: Bool = false
        
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
                        AppManager.shared.userInfo.accept(nil)
                        showNetworkErrorScreen.onNext(false)
                        return Observable.empty()
                    }).asDriverOnErrorJustComplete()
            })
            .flatMap({ screen -> Driver<ScreenLoadingType> in
                return self.useCase.getWebSettings(settingKey: SortVM.openfromScreen.folderCloud.textParam)
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
        
//        var isUpdateSortedAt: Bool = false
//        let sortedAtEvent: PublishSubject<String> = PublishSubject.init()
//        let exclusiveErrorEvent: PublishSubject<Void> = PublishSubject.init()
//
//        let sortAtEvent = sortedAtEvent
//            .withLatestFrom(useCase.hasLoggedin(), resultSelector: { (login: $1, sortedAt: $0) })
//            .do(onNext: { (login, sortedAt) in
//                guard login else { return }
//                exclusiveErrorEvent.onNext(())
//                if isUpdateSortedAt {
//                    AppSettings.sortAtFolder = sortedAt
//                } else if AppSettings.sortAtFolder != sortedAt {
//                    exclusiveErrorEvent.onNext(())
//                }
//            })
//            .asDriverOnErrorJustComplete()
//            .mapToVoid()
        var sortedAtValue: String = ""
        var isReloadSortedAt: Bool = false
        let reloadSortedAtEvent: PublishSubject<Void> = PublishSubject.init()
        
        let getResult = getPage(loadType: userAction,
                                retry: retryAction,
                                getItems: { offset -> Observable<PagingInfo<Folder>> in
            let realOffset = offset == 0 ? 1 : offset
            let request: Observable<PagingInfo<Folder>>
            request = useCase.fetchCloudFolders(offset: realOffset,
                                                limit: GlobalConstant.limitItemPerPage,
                                                sortMode: sortModel).map({ (page) -> PagingInfo<Folder> in
                DispatchQueue.main.async {
                    sortedAtValue = page.sortedAt
                    if isReloadSortedAt {
                        reloadSortedAtEvent.onNext(())
                    }
                }
                return page
            })
            
            return useCase.hasLoggedin()
                .flatMap ({ (loggedIn) -> Observable<PagingInfo<Folder>> in
                    if loggedIn {
                        return request
                    }
                    
                    AppManager.shared.userInfo.accept(nil)
                    
                    showNetworkErrorScreen.onNext(false)
                    return Observable.empty()
                })
                .catchError({ (error) -> Observable<PagingInfo<Folder>> in
                    if let error = error as? GooServiceError {
                        switch error {
                        case .maintenanceCannotUpdate(let data):
                            if let data = data as? PagingInfo<Folder> {
                                let paging = PagingInfo(offset: data.offset,
                                                        limit: data.limit,
                                                        totalItems: data.totalItems,
                                                        hasMorePages: data.hasMorePages,
                                                        items: data.items.map({ $0 }),
                                                        name: data.name)
                                
                                return Observable.just(())
                                    .withLatestFrom(onScreen)
                                    .filter({ $0 })
                                    .flatMap({ _ in
                                        self.navigator
                                            .showMessage(L10n.FolderBrowser.Error.maintenanceCannotUpdate)
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
                    if var userInfo = AppManager.shared.userInfo.value, userInfo.deviceStatus != .registered {
                        userInfo.deviceStatus = .registered
                        AppManager.shared.userInfo.accept(userInfo)
                    }
                })
                    })
        
        let error = getResult.error
            .withLatestFrom(onScreen, resultSelector: { (error: $0, onScreen: $1) })
            .filter({ $0.onScreen })
            .flatMap({ (error, _) -> Driver<Void> in
                if let error = error as? GooServiceError {
                    showNetworkErrorScreen.onNext(false)
                    
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
                
                return Driver.just(())
                    .do(onNext: {
                        showNetworkErrorScreen.onNext(true)
                    })
            })
        
        let folders = getResult.page
            .asDriver()
            .map({ page -> [Folder] in
                return [Folder(name: L10n.Folder.uncategorized, id: .cloud(""), manualIndex: nil, hasSortManual: false)] + page.items
            })
        
        // rename flow
        let renameFolder = input.renameAtIndexPath
            .withLatestFrom(folders, resultSelector: { (indexPath, list) -> Folder? in
                if list.count > indexPath.row {
                    return list[indexPath.row]
                }
                
                return nil
            })
            .compactMap({ $0 })
            .flatMapLatest({ folder in
                self.navigator.toRenameFolder(folder: folder)
                    .asDriverOnErrorJustComplete()
            })
            .mapToVoid()
        
        // delete flow
        
        let seletedFolder = input.deleteAtIndexPath
            .withLatestFrom(folders, resultSelector: { (indexPath, list) -> Folder? in
                if list.count > indexPath.row {
                    return list[indexPath.row]
                }
                
                return nil
            })
            .compactMap({ $0 })
        
        let deletedFolder = deleteFolderFlow(seletedFolder: seletedFolder, activityIndicator: activityIndicator)
        
        let movedToFolder = input.selectAtIndexPath
            .withLatestFrom(folders, resultSelector: { (indexPath, list) -> Folder? in
                if list.count > indexPath.row {
                    return list[indexPath.row]
                }
                
                return nil
            })
            .compactMap({ $0 })
            .do(onNext: navigator.toDraftList(in:))
        
        let hasDataStartWithNil: Driver<Bool?> = folders.map({ $0.count > 1 }).startWith(nil)
        
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
            .distinctUntilChanged()
        
        let showBanner = input.viewWillAppear
            .map({ BannerType.cloudFolders })
            .filter({ $0.isClosed == false })
            .asObservable()
            .take(1)
            .asDriverOnErrorJustComplete()
        
        let updateSortEventToHide: PublishSubject<SortModel> = PublishSubject.init()
        let updateSort = self.navigator.updateSort.asDriverOnErrorJustComplete()
            .do { sort in
                sortModel = sort
                reSortUpdateName.onNext(.loading)
                updateSortEventToHide.onNext(sort)
        }
        
        let moveToSort = input.moveToSort.do { _ in
            self.navigator.moveToSort(sortModel: sortModel)
        }
        
        let viewWillDisAppear = input.viewWillDisappear
            .map { _ -> SortModel in
                isActiveManual = false
                return SortModel(sortName: sortModel.sortName,
                                 asc: sortModel.asc,
                                 isActiveManual: isActiveManual)
            }
        
        let sortFoldersEvent = Driver.merge(reloadSortedAtEvent.asDriverOnErrorJustComplete().withLatestFrom(input.saveIndex, resultSelector: { ($1) }),
                                            input.saveIndex)
            .flatMap { (sort, folder) -> Driver<Void> in
                return self.useCase.sortFolders(folders: folder, sortedAt: sortedAtValue)
                    .trackError(errorTrackerWebSetting)
                    .asDriverOnErrorJustComplete()
                    .do { _ in
                        isReloadSortedAt = false
                        reloadAfterSortedAtManual.onNext(.loading)
                    }
                    .mapToVoid()
            }
        
        let reUpdateFolders: PublishSubject<SortModel> = PublishSubject.init()
        let showButton: PublishSubject<Void> = PublishSubject.init()
        let sortUpdateEvent = Driver.merge(getSort.asDriverOnErrorJustComplete(),
                                           self.navigator.updateSort.asDriverOnErrorJustComplete(),
                                           viewWillDisAppear,
                                           reUpdateFolders.asDriverOnErrorJustComplete())
        
        
        let errorWebSettings = errorTrackerWebSetting
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
                        sortModel = SortModel.valueDefault
                        webSettingNotFound.onNext(.reloading)
                    case .receiptInvalid:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Error.receiptInvalid)
                            .asDriverOnErrorJustComplete()
                    case .exclusiveError:
                        return self.navigator.showMessage(L10n.FolderBrowser.Error.exclusiveError)
                            .do { _ in
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
                
                return Driver.just(())
            })
            .asDriverOnErrorJustComplete()
        
//        let reloadSortedAtFlow = reloadSortedAtEvent
//            .flatMap { self.useCase.postWebSetiings(sortMode: SortModel(sortName: .manual, asc: sortModel.asc, isActiveManual: false)) }
//            .do { value in
////                isReloadSortedAt = false
////                reSortUpdateName.onNext(.loading)
//            }
//            .mapToVoid()
//            .asDriverOnErrorJustComplete()

        
        let hide = updateSortEventToHide
            .map { sort -> Bool in
                switch sort.sortName {
                case .manual: return true
                case .created_at, .free, .title, .updated_at: return false
                }
            }
            .asDriverOnErrorJustComplete()
        
        let show = Driver.merge(sortFoldersEvent.mapToVoid(),
                                viewWillDisAppear.mapToVoid(),
                                showButton.asDriverOnErrorJustComplete(),
                                input.refreshTrigger.mapToVoid()).map { _ in false }

        let hideButton = Driver.merge(hide, show).do { hide in
            self.hideButtonCreate.onNext(hide)
        }
        
        
        
        return Output(
            error: error,
            isLoading: getResult.isLoading,
            isReloading: getResult.isReloading,
            folders: folders,
            movedToFolder: movedToFolder,
            renamedFolder: renameFolder,
            deletedFolder: deletedFolder,
            loading: activityIndicator.asDriver(),
            screenState: screenState,
            showBanner: showBanner,
            moveToSort: moveToSort,
            updateSort: updateSort,
            sortUpdateEvent: sortUpdateEvent,
            errorWebSettings: errorWebSettings,
            hideButton: hideButton,
            reUpdateFolders: reUpdateFolders.mapToVoid().asDriverOnErrorJustComplete()
//            reloadSortedAtFlow: reloadSortedAtFlow
//            sortAtEvent: sortAtEvent.mapToVoid()
        )
    }
    
    private func deleteFolderFlow(seletedFolder: Driver<Folder>, activityIndicator: ActivityIndicator) -> Driver<Void> {
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
                            .showMessage(L10n.FolderBrowser.Error.unregisteredDevice)
                            .asDriverOnErrorJustComplete()
                        
                    case .folderNotFound:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Delete.Error.folderNotFound)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                NotificationCenter.default.post(name: .didUpdateCloudFolder, object: nil)
                            })
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.FolderBrowser.Delete.Error.maintenance)
                            .asDriverOnErrorJustComplete()
                        
                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
                            .asDriverOnErrorJustComplete()
                        
                    case .sessionTimeOut:
                        return self.useCase.refreshSession()
                            .trackActivity(activityIndicator)
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
        
        let userAction = seletedFolder
            .mapToVoid()
            .do(onNext: {
                retry.accept(0)
            })
            .flatMap({
                // Show the confirmation dialog before deleting the selected folder
                self.navigator.toConfirmationDeletion().asDriverOnErrorJustComplete().filter({ $0 })
            })
            .mapToVoid()
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let deleteFolder = Driver.merge(userAction, retryAction)
            .withLatestFrom(seletedFolder)
            .asObservable()
            .flatMap({ (folder) -> Driver<(folderId: String, drafts: [Document])> in
                // Get total drafts in the folder, then, get all drafts detail
                if let folderId = folder.id.cloudID {
                    return self.useCase.numberOfDrafts(in: folderId)
                        .flatMap({ number -> Observable<[Document]> in
                            if number > 0 {
                                return self.useCase.fetchDrafts(inCloudfolder: folderId, totalItems: number)
                            }
                            
                            return Observable.just([])
                        })
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .asDriverOnErrorJustComplete()
                        .map({ (folderId: folderId, drafts: $0) })
                }
                
                return Driver.empty()
            })
            .flatMap({ data -> Driver<(folderId: String, drafts: [Document])> in
                // save it to Trash
                if data.drafts.count > 0 {
                    return self.useCase.saveToTrash(drafts: data.drafts)
                        .catchError({ (error) -> Observable<()> in
                            return self.navigator
                                .showMessage(L10n.Error.otherErrorAtLocal)
                                .flatMap({ Observable.empty() })
                        })
                        .map({ data })
                        .asDriverOnErrorJustComplete()
                }
                
                return Driver.just(data)
            })
            .flatMap({ data -> Driver<Void> in
                // Delete the cloud folder
                self.useCase.deleteCloudFolder(folderId: data.folderId)
                    .trackActivity(activityIndicator)
                    .asDriverOnErrorJustComplete()
                    .do(onNext: {
                        NotificationCenter.default.post(name: .didUpdateCloudFolder, object: nil)
                    })
            })
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        return Driver.merge(deleteFolder, errorHandler)
    }
}
