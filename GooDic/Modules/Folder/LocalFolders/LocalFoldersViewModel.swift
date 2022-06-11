//
//  LocalFoldersViewModel.swift
//  GooDic
//
//  Created by ttvu on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

import Foundation
import RxSwift
import RxCocoa
import CoreData

enum LocalFolderListCellData: Equatable {
    case unknown
    case addFolder
    case uncategorizedFolder
    case folder(IndexPath)
}

struct LocalFoldersViewModel {
    let navigator: LocalFoldersNavigateProtocol
    let useCase: LocalFoldersUseCaseProtocol
    let countUncategoriedDrafts = BehaviorRelay<Int>(value: 0)
    let updateList: PublishSubject<Void> = PublishSubject.init()
    let hideButtonCreate: PublishSubject<Bool> = PublishSubject.init()
    let dataSource: FolderDataSourceProxy!
    
    init(navigator: LocalFoldersNavigateProtocol, useCase: LocalFoldersUseCaseProtocol) {
        self.navigator = navigator
        self.useCase = useCase
        self.dataSource = FolderDataSourceProxy(fetchedResultsController: useCase.fetchedResultsController,
                                                extendedCells: [.uncategorizedFolder])
    }
}

extension LocalFoldersViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
        let viewWillDisAppear: Driver<Void>
        let updateUITrigger: Driver<Void>
        let viewDidAppearTrigger: Driver<Void>
        let viewDidLayoutSubviewsTrigger: Driver<Void>
        let renameAtIndexPath: Driver<IndexPath>
        let deleteAtIndexPath: Driver<IndexPath>
        let selectAtIndexPath: Driver<IndexPath>
        let selectUncategorizedFolder: Driver<Void>
        let interactWithSwipeFolderTutorialTrigger: Driver<Void>
        let checkedNewUserTrigger: Driver<Bool>
        let moveToSort: Driver<Void>
        let saveIndex: Driver<SortModel>
    }
    
    struct Output {
        let folderCount: Driver<Int>
        let renamedFolder: Driver<Void>
        let deletedFolder: Driver<Void>
        let selectedFolder: Driver<Void>
        let showSwipeFolderTutorial: Driver<Bool>
        let autoHideTooltips: Driver<Void>
        let updateSort: Driver<SortModel>
        let moveToSort: Driver<Void>
        let reSortUpdateName: Driver<Void>
        let updateList: Driver<Void>
        let hideButton: Driver<Bool>
        let saveFolderEventGreaterThan: Driver<Bool?>
    }
    
    func transform(_ input: Input) -> Output {
        let reSortUpdateName: PublishSubject<Void> = PublishSubject.init()
        let renameFolder = input.renameAtIndexPath
            .map(self.dataSource.dataIndexPath(from:))
            .compactMap({ (data) -> IndexPath? in
                if case let FolderCellType.folder(indexPath) = data {
                    return indexPath
                }
                
                return nil
            })
            .map({ idx -> Folder in
                return self.dataSource.folders[idx.row].folder
            })
            .flatMapLatest({ folder in
                self.navigator.toRenameFolder(folder: folder)
                    .asDriverOnErrorJustComplete()
            })
            .do(onNext: { result in
                switch result {
                case .cancel, .updatedCloudFolder: break
                case .updatedLocalFolder:
                    reSortUpdateName.onNext(())
                }
            })
            .mapToVoid()
        let deletedFolder = input.deleteAtIndexPath
            .map(self.dataSource.dataIndexPath(from:))
            .compactMap({ (data) -> IndexPath? in
                if case let FolderCellType.folder(indexPath) = data {
                    return indexPath
                }
                
                return nil
            })
            .map({ idx -> Folder in
                return self.dataSource.folders[idx.row].folder
            })
            .flatMap({ folder -> Driver<Void> in
                let showConfirmationIfNeeded: Observable<Bool>
                if folder.documents.isEmpty {
                    showConfirmationIfNeeded = Observable.just(true)
                } else {
                    showConfirmationIfNeeded = self.navigator.toConfirmationDeletion()
                }
                
                return showConfirmationIfNeeded
                    .flatMap ({ (result) -> Observable<Void> in
                        if result {
                            return self.useCase.deleteFolder(folder: folder)
                        } else {
                            return Observable.empty()
                        }
                    })
                    .asDriverOnErrorJustComplete()
            })
            .mapToVoid()
        
        let selectedFolder = input.selectAtIndexPath
            .map(self.dataSource.dataIndexPath(from:))
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
            .do(onNext: { self.navigator.toDraftList(in: $0) })
            .mapToVoid()
        
        // show tooltip
        let autoHideSwipeFolderTooltipTrigger = PublishSubject<Void>()
        
        let learnedSwipeFolderTutorial = Driver
            .merge(
                input.interactWithSwipeFolderTutorialTrigger,
                autoHideSwipeFolderTooltipTrigger.asDriverOnErrorJustComplete())
            .asObservable()
            .take(1)
            .flatMapLatest(self.useCase.learnedSwipeFolderTutorial)
            .asDriverOnErrorJustComplete()
        
        let folderCount = input.updateUITrigger
            .map({ self.useCase.fetchedResultsController.fetchedObjects?.count ?? 0 })
        
        let hasData = folderCount.map({ $0 > 0 })
        
        let showSwipeFolderTutorial = Driver
            .merge(
                hasData.mapToVoid(),
                learnedSwipeFolderTutorial)
            .asObservable()
            .skipUntil(input.checkedNewUserTrigger.asObservable())
            .map({ self.useCase.showSwipeActionInFolder() })
            .asDriverOnErrorJustComplete()
            .distinctUntilChanged()
        
        let autoHideTooltips = showSwipeFolderTutorial
            .filter({ $0 })
            .mapToVoid()
            .delay(.seconds(GlobalConstant.tooltipDuration))
            .do(onNext: { autoHideSwipeFolderTooltipTrigger.onNext(()) })
        var isActiveManual: Bool = false
        
        let viewWillDisAppear = input.viewWillDisAppear
            .map { _ -> SortModel in
                isActiveManual = false
                AppSettings.sortModel = SortModel(sortName: AppSettings.sortModel.sortName,
                                                  asc: AppSettings.sortModel.asc,
                                                  isActiveManual: isActiveManual)
                self.dataSource.updateFolders(sort: AppSettings.sortModel, isSave: false)
                return AppSettings.sortModel
            }
        
        let getSortformSetting = Driver.just(AppSettings.sortModel)
            .map { sort -> SortModel in
                AppSettings.sortModel = SortModel(sortName: sort.sortName, asc: sort.asc, isActiveManual: isActiveManual)
                return AppSettings.sortModel
            }
        
        let updateSortEventToHide: PublishSubject<SortModel> = PublishSubject.init()
        let updateSortfromVC = self.navigator.updateSort.asDriverOnErrorJustComplete()
            .do { sort in
                isActiveManual = true
                AppSettings.sortModel = sort
                switch sort.sortName {
                case .manual:
                    if AppSettings.hasSortManualFolder {
                        self.dataSource.sortFolder(isSave: false)
                    } else {
                        AppSettings.hasSortManualFolder = true
                    }
                case .created_at, .free, .title, .updated_at:
                    self.dataSource.sortFolder(isSave: false)
                }
                
                updateSortEventToHide.onNext(sort)
        }
        
        let updateSort = Driver.merge(getSortformSetting,
                                      updateSortfromVC,
                                      viewWillDisAppear,
                                      input.saveIndex.do(onNext: { _ in
                                        self.useCase.updateIndexFolder(folders: self.saveIndexFolder(folders: self.dataSource.folders.map { $0.folder }))
                                      }))
        
        let moveToSort = input.moveToSort.do { _ in
            self.navigator.moveToSort(sortModel: AppSettings.sortModel)
        }
        
        let updateList = self.updateList.do { _ in
            self.dataSource.sortFolder(isSave: false)
        }
        .asDriverOnErrorJustComplete()
        
        let hide = updateSortEventToHide
            .map { sort -> Bool in
                switch sort.sortName {
                case .manual: return true
                case .created_at, .free, .title, .updated_at: return false
                }
            }
            .asDriverOnErrorJustComplete()
        let show = Driver.merge(input.saveIndex.mapToVoid(), viewWillDisAppear.mapToVoid()).map { _ in false }
        
        let hideButton = Driver.merge(hide, show).do { hide in
            self.hideButtonCreate.onNext(hide)
        }
        
        let saveFolderEventGreaterThan = self.dataSource.saveFoldersEvent.do { isSave in
            guard let isSave = isSave else { return }
            if isSave {
                self.useCase.updateIndexFolder(folders: self.saveIndexFolder(folders: self.dataSource.folders.map { $0.folder }))
            }
        }.asDriverOnErrorJustComplete()

        
        return Output(
            folderCount: folderCount,
            renamedFolder: renameFolder,
            deletedFolder: deletedFolder,
            selectedFolder: selectedFolder,
            showSwipeFolderTutorial: showSwipeFolderTutorial,
            autoHideTooltips: autoHideTooltips,
            updateSort: updateSort,
            moveToSort: moveToSort,
            reSortUpdateName: reSortUpdateName.asDriverOnErrorJustComplete(),
            updateList: updateList,
            hideButton: hideButton,
            saveFolderEventGreaterThan: saveFolderEventGreaterThan
        )
    }
    
    private func saveIndexFolder(folders: [Folder] ) -> [Folder] {
        var d = folders
        
        folders.enumerated().forEach { (item) in
            let element = item.element
            let offset = item.offset
            if let index = d.firstIndex(where: { $0.id == element.id }) {
                d[index].manualIndex = Double(folders.count - offset)
            }
        }
        
        return d
    }
}
