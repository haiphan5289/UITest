//
//  CloudFolderSelectionViewModel.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct CloudFolderSelectionViewModel: ViewModelProtocol {
    let useCase: CloudFolderSelectionUserCaseProtocol
    let navigator: CloudFolderSelectionNavigateProtocol
    let drafts: [Document]
    
    let delegate: PublishSubject<SelectionResult>
    let disabledFolderId: FolderId?
    
    init(useCase: CloudFolderSelectionUserCaseProtocol, navigator: CloudFolderSelectionNavigateProtocol, delegate: PublishSubject<SelectionResult>, drafts: [Document]) {
        self.useCase = useCase
        self.navigator = navigator
        self.delegate = delegate
        self.drafts = drafts
        
        // we're going to make this folder be unselectable
        self.disabledFolderId = FolderId.findSameFolderId(drafts.map({ $0.folderId }))
    }
}

extension CloudFolderSelectionViewModel: PagingFeature {
    struct Input {
        let userInfo: Driver<UserInfo?>
        let loadDataTrigger: Driver<Void>
        let refreshTrigger: Driver<Void>
        let loadMoreTrigger: Driver<Void>
        let forceReload: Driver<Void>
        let viewWillAppear: Driver<Void>
        let viewDidAppear: Driver<Void>
        let selectAtIndexPath: Driver<IndexPath>
    }
    
    struct Output {
        // paging
        let error: Driver<Void>
        let isLoading: Driver<Bool>
        let isReloading: Driver<Bool>
        
        // update UI data
        let cellDatas: Driver<[FolderCellData]>
        let screenState: Driver<CloudScreenState>
        
        // action
        let createFolder: Driver<UpdateFolderResult>
        let moved: Driver<Void>
        let loading: Driver<Bool>
        
        // Banner
        let showBanner: Driver<BannerType>
    }
    
    func transform(_ input: Input) -> Output {
        let showNetworkErrorScreen = BehaviorSubject<Bool?>(value: nil)
        
        let retryLoadData = BehaviorRelay<Int>(value: 0)
        
        let draftsStream = Driver.just(drafts)
        
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
        
        let refreshTrigger = input.refreshTrigger.map({ ScreenLoadingType.reloading })
        let loadMoreTrigger = input.loadMoreTrigger.map({ ScreenLoadingType.loadMore })
        
        let userActionLoad = Driver.merge(loadTrigger, refreshTrigger, loadMoreTrigger)
            .filter({ _ in AppSettings.userInfo?.deviceStatus != DeviceStatus.unregistered })
            .do(onNext: { _ in
                retryLoadData.accept(0)
            })
        
        let retryAction = retryLoadData.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let getResult = getPage(loadType: userActionLoad,
                                retry: retryAction,
                                getItems: { offset -> Observable<PagingInfo<Folder>> in
                                    let realOffset = offset == 0 ? 1 : offset
                                    let request: Observable<PagingInfo<Folder>>
                                    request = useCase.fetchCloudFolders(offset: realOffset,
                                                                  limit: GlobalConstant.limitItemPerPage)
                                    return useCase.hasLoggedin()
                                        .flatMap ({ (loggedIn) -> Observable<PagingInfo<Folder>> in
                                            if loggedIn {
                                                return request
                                            }
                                            
                                            showNetworkErrorScreen.onNext(false)
                                            return Observable.empty()
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
            .flatMap({ (error) -> Driver<Void> in
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
                        
                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.Maintenance.cannotMoveToCloudFolder)
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
            .startWith(PagingInfo<Folder>(offset: 0, limit: 0, totalItems: 0, hasMorePages: false, items: []))
            .map({ $0.items })
            .map({ (list) -> [Folder] in
                let additionFolderBtn = Folder(name: L10n.Folder.createFolder, id: .none, manualIndex: nil, hasSortManual: false)
                let uncategorizedFolder = Folder.uncatetorizedCloudFolder
                return [additionFolderBtn, uncategorizedFolder] + list
            })
        
        let cellDatas = folders
            .map({ folders -> [FolderCellData] in
                folders.map({ FolderCellData(name: $0.name, id: $0.id, disable: $0.id != .none && $0.id == self.disabledFolderId) })
            })
        
        let userDidSelected = input.selectAtIndexPath
            .withLatestFrom(folders, resultSelector: { (indexPath, list) -> Folder? in
                if list.count > indexPath.row {
                    return list[indexPath.row]
                }
                
                return nil
            })
            .compactMap({ $0 })
        
        let createFolder = userDidSelected
            .filter({ $0.id == .none }) // it's the create folder cell
            .flatMapLatest({ _ in
                self.navigator.toCreationFolder(createCloudFolderAsDefault: true)
                    .asDriverOnErrorJustComplete()
            })
        
        let selectedFolder = userDidSelected
            .filter({ $0.id != .none }) // it's not the create folder cell
            .filter({ $0.id != self.disabledFolderId }) // it's not the disabled folder cell
        
        let activityIndicator = ActivityIndicator()
        let moved = moveDraftsFlow(drafts: draftsStream,
                                   folder: selectedFolder,
                                   activityIndicator: activityIndicator,
                                   errorNetwork: showNetworkErrorScreen)
        
        let hasDataStartWithNil: Driver<Bool?> = folders.map({ !$0.isEmpty }).startWith(nil)
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
            .map({ BannerType.selectionCloudFolder })
            .filter({ $0.isClosed == false })
            .asObservable()
            .take(1)
            .asDriverOnErrorJustComplete()
        
        return Output(
            error: error,
            isLoading: getResult.isLoading,
            isReloading: getResult.isReloading,
            cellDatas: cellDatas,
            screenState: screenState,
            createFolder: createFolder,
            moved: moved,
            loading: activityIndicator.asDriver(),
            showBanner: showBanner
        )
    }
    
    func moveDraftsFlow(drafts: Driver<[Document]>,
                        folder: Driver<Folder>,
                        activityIndicator: ActivityIndicator,
                        errorNetwork: BehaviorSubject<Bool?>) -> Driver<Void> {
        let retry = BehaviorRelay<Int>(value: 0)
        let moveLocalDraftToCloudErrorTracker = ErrorTracker()
        let moveLocalDraftToCloudErrorHandler = moveLocalDraftToCloudErrorTracker
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
                            .showMessage(L10n.FolderSelection.Error.folderNotFound)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                NotificationCenter.default.post(name: .didUpdateCloudFolder, object: nil)
                            })

                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.Maintenance.cannotMoveToCloudFolder)
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
                        
                    case .limitRegistrtion:
                        
                        var msg: String
                        if AppManager.shared.billingInfo.value.billingStatus == .paid {
                            msg = L10n.Creation.Error.movelimitPaid
                        } else {
                            msg = L10n.Creation.Error.movelimit
                        }
                        
                        return self.navigator
                            .showMessage(msg)
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
                        errorNetwork.onNext(true)
                    })
            })
        
        let moveCloudDraftToCloudErrorTracker = ErrorTracker()
        let moveCloudDraftToCloudErrorHandler = moveCloudDraftToCloudErrorTracker
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
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                            .withLatestFrom(drafts)
                            .mapToVoid()
                            .do(onNext: {
                                NotificationCenter.default.post(name: .didUpdateCloudDrafts, object: nil)
                                self.navigator.dismiss()
                            })
                        
                    case .folderNotFound:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.folderNotFound)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                NotificationCenter.default.post(name: .didUpdateCloudFolder, object: nil)
                            })

                    case .maintenance, .maintenanceCannotUpdate:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.Maintenance.cannotMoveToCloudFolder)
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
                        
                    case .limitRegistrtion:
                        
                        var msg: String
                        if AppManager.shared.billingInfo.value.billingStatus == .paid {
                            msg = L10n.Creation.Error.movelimitPaid
                        } else {
                            msg = L10n.Creation.Error.movelimit
                        }
                        
                        return self.navigator
                            .showMessage(msg)
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
                        errorNetwork.onNext(true)
                    })
            })
        
        let userAction = Driver.combineLatest(drafts, folder)
            .do(onNext: { _ in
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        let moved = Driver.merge(userAction.mapToVoid(), retryAction)
            .withLatestFrom(userAction)
            .flatMap({ drafts, folder -> Driver<Folder> in
                guard let isCloudDraft = drafts.first?.onCloud else { return Driver.empty() }
                
                if isCloudDraft {
                    return self.useCase.move(cloudDrafts: drafts, toCloudFolderId: folder.id.cloudID ?? "")
                        .trackActivity(activityIndicator)
                        .trackError(moveCloudDraftToCloudErrorTracker)
                        .asDriverOnErrorJustComplete()
                        .map({ folder })
                }
                
                return self.useCase.move(localDrafts: drafts, toCloudFolderId: folder.id.cloudID ?? "")
                    .trackActivity(activityIndicator)
                    .trackError(moveLocalDraftToCloudErrorTracker)
                    .asDriverOnErrorJustComplete()
                    .flatMapLatest({ self.useCase
                        .delete(localDrafts: drafts)
                        .asDriverOnErrorJustComplete()
                    })
                    .map({ folder })
            })
            .do(onNext: { folder in
                self.delegate.onNext(.done(folder))
                self.navigator.dismiss()
            })
            .mapToVoid()
        
        return Driver.merge(moved, moveCloudDraftToCloudErrorHandler, moveLocalDraftToCloudErrorHandler)
    }
}
