//
//  LocalFolderSelectionViewModel.swift
//  GooDic
//
//  Created by ttvu on 11/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

enum SelectionResult {
    case cancel
    case done(Folder)
}

struct FolderCellData {
    let name: String
    let id: FolderId
    let disable: Bool
}

struct LocalFolderSelectionViewModel {
    let navigator: LocalFolderSelectionNavigateProtocol
    let useCase: LocalFolderSelectionUseCaseProtocol
    let drafts: [Document]
    let draftOrigin: [Document]
    
    let delegate: PublishSubject<SelectionResult>
    let disabledFolderId: FolderId?
    
    let dataSource: FolderDataSourceProxy
    
    init(useCase: LocalFolderSelectionUseCaseProtocol, navigator: LocalFolderSelectionNavigateProtocol, delegate: PublishSubject<SelectionResult>, drafts: [Document], draftOrigin: [Document]) {
        self.useCase = useCase
        self.navigator = navigator
        self.delegate = delegate
        self.drafts = drafts
        self.draftOrigin = draftOrigin
        // we're going to make this folder be unselectable
        self.disabledFolderId = FolderId.findSameFolderId(drafts.map({ $0.folderId }))
        self.dataSource = FolderDataSourceProxy(fetchedResultsController: useCase.fetchedResultsController, extendedCells: [.addFolder, .uncategorizedFolder])
    }
}

extension LocalFolderSelectionViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
        let selectAtIndexPath: Driver<IndexPath>
    }
    
    struct Output {
        let createdFolder: Driver<UpdateFolderResult>
        let moved: Driver<Void>
        let loading: Driver<Bool>
    }
    
    func transform(_ input: Input) -> Output {
        let draftsStream = Driver.just(drafts)
        
        let userDidSelected = input.selectAtIndexPath
            .map(self.dataSource.dataIndexPath(from:))
        
        let createdFolder = userDidSelected
            .filter({ $0 == .addFolder })
            .withLatestFrom(self.dataSource.foldersEvent.asDriverOnErrorJustComplete(), resultSelector: { ( isCloud: $0, folder: $1 ) })
            .flatMapLatest { (isCloud, folders) -> Driver<UpdateFolderResult> in
                let valueIndex = (folders.map { $0.folder }.map { $0.manualIndex }.compactMap { $0 }.max() ?? 0) + 1
                return self.navigator.toCreationFolder(createCloudFolderAsDefault: false, valueIndex: valueIndex)
                    .asDriverOnErrorJustComplete()
            }
        
        let userDidSelectedFolder = userDidSelected
            .filter({ $0 != .addFolder })
            .map({ (data) -> IndexPath? in
                if case let FolderCellType.folder(indexPath) = data {
                    return indexPath
                }
                return nil
            })
            .map({ indexPath -> Folder? in
                guard let indexPath = indexPath else { return nil }
                
                return self.dataSource.folders[indexPath.row].folder
            })
            .map({ $0 ?? Folder.uncatetorizedLocalFolder})
            .filter({ $0.id != self.disabledFolderId })
            
        let activityIndicator = ActivityIndicator()
        let moved = moveDraftsFlow(drafts: draftsStream,
                                   folder: userDidSelectedFolder,
                                   activityIndicator: activityIndicator)
        
        
        return Output(
            createdFolder: createdFolder,
            moved: moved,
            loading: activityIndicator.asDriver()
        )
    }
    
    func moveDraftsFlow(drafts: Driver<[Document]>, folder: Driver<Folder>, activityIndicator: ActivityIndicator) -> Driver<Void> {
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
                        
                    case .draftNotFound:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.draftNotFound)
                            .asDriverOnErrorJustComplete()
                            .do(onNext: {
                                NotificationCenter.default.post(name: .didUpdateCloudDrafts, object: nil)
                                self.navigator.dismiss()
                            })

                    case .maintenance:
                        return self.navigator
                            .showMessage(L10n.FolderSelection.Error.Maintenance.draftsCannotBeMovedFromCloud)
                            .asDriverOnErrorJustComplete()
                        
                    case .maintenanceCannotUpdate:
                        return Driver.empty()

                    case .authenticationError:
                        return self.useCase.logout()
                            .subscribeOn(MainScheduler.instance)
                            .do(onNext: self.navigator.toForceLogout)
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
        
        let userAction = Driver.combineLatest(drafts, folder)
            .do(onNext: { _ in
                retry.accept(0)
            })
        
        let retryAction = retry.asDriver()
            .filter({ $0 > 0 })
            .mapToVoid()
        
        var docsCloud: [Document] = []
        let getDocsCloud = self.useCase.getDocsCloud.do { docs in
            docsCloud = docs
        }
        .mapToVoid()
        .asDriverOnErrorJustComplete()

        
        let moved = Driver.merge(userAction.mapToVoid(), retryAction)
            .withLatestFrom(userAction)
            .flatMap({ drafts, folder -> Driver<Folder> in
                guard let isCloudDraft = drafts.first?.onCloud else { return Driver.empty() }
                
                if isCloudDraft {
                    return self.useCase.fetchDetail(cloudDrafts: drafts)
                        .catchError({ (error) -> Observable<[Document]> in
                            if let error = error as? GooServiceError {
                                switch error {
                                case .maintenanceCannotUpdate(let data):
                                    if let list = data as? [Document] {
                                        return self.navigator
                                            .showMessage(L10n.FolderSelection.Error.maintenanceCannotUpdate)
                                            .map({ list.map({ $0 }) })
                                    }
                                    else if let data = data as? Document {
                                        return self.navigator
                                            .showMessage(L10n.FolderSelection.Error.maintenanceCannotUpdate)
                                            .map({ [data] })
                                    }

                                default:
                                    break
                                }
                            }

                            return Observable.error(error)
                        })
                        .flatMap ({ listDetail -> Observable<Void> in
                            return self.useCase.save(cloudDrafts: self.updateDraftFromCloud(folder: folder, listDetail: listDetail), toLocalFolderId: folder.id.localID ?? "")
                                .catchError({ (error) -> Observable<Void> in
                                    return self.navigator
                                        .showMessage(L10n.Error.otherErrorAtLocal)
                                        .flatMap({ Observable.empty() })
                                })
                        })
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .flatMap({
                            self.useCase.delete(cloudDrafts: drafts)
                                .asDriver(onErrorJustReturn: ())
                        })
                        .asDriverOnErrorJustComplete()
                        .map { _ -> Folder in
                            
                            switch folder.id {
                            case .none, .cloud: break
                            case .local(let id):
                                if id.isEmpty {
                                    switch AppSettings.sortModelDraftsUncategorized.sortName {
                                    case .manual:
                                        docsCloud.enumerated().forEach { item in
                                            let element = item.element
                                            let offset = item.offset
                                            let manualindex: FolderDataSourceProxy.ManualIndex = FolderDataSourceProxy.ManualIndex(id: element.id , index: offset)
                                            if (AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == manualindex.id }) == nil) {
                                                AppSettings.draftManualIndexUncategorized.insert(manualindex, at: 0)
                                            }
                                        }
                                    case .title, .created_at, .free, .updated_at: break
                                    }
                                }
                            }
                            
                            return folder
                        }
                }
                
                return self.useCase.move(localDrafts: self.updateDraft(folder: folder), toLocalFolderId: folder.id.localID ?? "")
                    .asDriverOnErrorJustComplete()
                    .map { folder }
            })
            .do(onNext: { folder in
                self.delegate.onNext(.done(folder))
                self.navigator.dismiss()
            })
            .mapToVoid()
        
        return Driver.merge(moved, errorHandler, getDocsCloud)
    }
    
    private func rearrangeDocuments(docs: [Document], sortManualIndex: [FolderDataSourceProxy.ManualIndex]) -> [Document] {
        var reDocs = docs
        sortManualIndex.enumerated().forEach { item in
            let element = item.element
            let offset = item.offset
            if let index = reDocs.firstIndex(where: { $0.id == element.id }) {
                let d = reDocs[index]
                reDocs.remove(at: index)
                reDocs.insert(d, at: offset)
            }
        }
        return reDocs
    }
    
    private func updateDraftFromCloud(folder: Folder, listDetail: [Document]) -> [Document] {
        var updateDrafts = listDetail
        switch folder.id {
        case .none, .cloud: break
        case .local(let id):
            var sort: SortModel
            
            if id.isEmpty {
                sort = AppSettings.sortModelDraftsUncategorized
            } else {
                sort = folder.getSortModel()
            }
            
            switch sort.sortName {
            case .manual:
                updateDrafts = []
                self.draftOrigin.forEach { doc in
                    if let index = listDetail.firstIndex(where: { $0.id == doc.id }) {
                        updateDrafts.append(listDetail[index])
                    }
                }
                updateDrafts.reverse()
                if !id.isEmpty {
                    
                    var docsFolder = folder.documents
                    
                    updateDrafts.enumerated().forEach { (item) in
                        let offset = item.offset
                        let max = (docsFolder.map{ $0.manualIndex }.compactMap { $0 }.max() ?? 0) + 1
                        updateDrafts[offset].manualIndex = max
                        docsFolder.append(updateDrafts[offset])
                    }
                }
                
            case .created_at, .free, .title, .updated_at: break
            }
        }
        
        return updateDrafts
    }
    
    private func updateDraft(folder: Folder) -> [Document] {
        var updateDrafts = self.drafts
        switch folder.id {
        case .none, .cloud: break
        case .local(let id):
            var sort: SortModel
            
            if id.isEmpty {
                sort = AppSettings.sortModelDraftsUncategorized
            } else {
                sort = folder.getSortModel()
            }
            
            switch sort.sortName {
            case .manual:
                updateDrafts = []
                self.draftOrigin.forEach { doc in
                    if let index = self.drafts.firstIndex(where: { $0.id == doc.id }) {
                        updateDrafts.append(self.drafts[index])
                    }
                }
                updateDrafts.reverse()
                if !id.isEmpty {
                    
                    var docsFolder = folder.documents
                    
                    updateDrafts.enumerated().forEach { (item) in
                        let offset = item.offset
                        let max = (docsFolder.map{ $0.manualIndex }.compactMap { $0 }.max() ?? 0) + 1
                        updateDrafts[offset].manualIndex = max
                        docsFolder.append(updateDrafts[offset])
                    }
                } else {
                    updateDrafts.enumerated().forEach { item in
                        let element = item.element
                        let offset = item.offset
                        let manualindex: FolderDataSourceProxy.ManualIndex = FolderDataSourceProxy.ManualIndex(id: element.id , index: offset)
                        if (AppSettings.draftManualIndexUncategorized.firstIndex(where: { $0.id == manualindex.id }) == nil) {
                            AppSettings.draftManualIndexUncategorized.insert(manualindex, at: 0)
                        }
                        
                    }
                }
                
            case .created_at, .free, .title, .updated_at: break
            }
        }
        
        return updateDrafts
    }
}


