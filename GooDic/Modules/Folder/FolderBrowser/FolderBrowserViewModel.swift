//
//  FolderBrowserViewModel.swift
//  GooDic
//
//  Created by ttvu on 9/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CoreData

enum FolderCellType: Equatable {
    case unknown
    case addFolder
    case uncategorizedFolder
    case folder(IndexPath)
}

struct FolderBrowserViewModel {
    let navigator: FolderBrowserNavigateProtocol
    let delegate: PublishSubject<SelectionResult>?
    let isMoveCloudDraft: Bool
    
    init(navigator: FolderBrowserNavigateProtocol,
         delegate: PublishSubject<SelectionResult>? = nil,
         isMoveCloudDraft: Bool = false) {
        self.navigator = navigator
        self.delegate = delegate
        self.isMoveCloudDraft = isMoveCloudDraft
    }
}

extension FolderBrowserViewModel: ViewModelProtocol {
    struct Input {
        let loadData: Driver<Void>
        let viewWillAppear: Driver<Void>
        let createFolderTrigger: Driver<Void>
        let dismissTrigger: Driver<Void>
        let isCloudTrigger: Driver<Bool>
        let cloudScreenState: Driver<CloudScreenState>
        let userInfo: Driver<UserInfo?>
        let foldersEvent: Driver<[CDFolder]>
    }
    
    struct Output {
        let title: Driver<String>
        let openCloudSegment: Driver<Bool>
        let hideCreationButton: Driver<Bool>
        let hideDismissButton: Driver<Bool>
        let createdFolder: Driver<UpdateFolderResult>
        let close: Driver<Void>
        let showPremium: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let createdFolder = input.createFolderTrigger
            .withLatestFrom(input.isCloudTrigger)
            .withLatestFrom(input.foldersEvent, resultSelector: { ( isCloud: $0, folder: $1 ) })
            .flatMapLatest { (isCloud, folders) -> Driver<UpdateFolderResult> in
                let valueIndex: Double = (folders.map { $0.folder }.map { $0.manualIndex }.compactMap { $0 }.max() ?? 0) + 1
                return self.navigator.toCreationFolder(createCloudFolderAsDefault: isCloud, valueIndex: valueIndex)
                    .asDriverOnErrorJustComplete()
            }
        
        let isFolderSelection = input.loadData
            .map({ self.delegate != nil })
        
        let hideDismissButton = isFolderSelection
            .map({ !$0 })
                
        let title = hideDismissButton
            .map({ $0 ? L10n.Folder.Browser.title : L10n.Folder.Selection.title })
        
        let openCloudSegment = Driver.just(self.isMoveCloudDraft)
        
        let close = input.dismissTrigger
            .do(onNext: {
                self.delegate?.onNext(.cancel)
                self.navigator.dismiss()
            })
        
        let hideCreationButton = Driver
            .combineLatest(
                input.loadData,
                isFolderSelection,
                input.isCloudTrigger,
                input.userInfo,
                input.cloudScreenState)
            .map({ _, isSelectFolder, isCloud, userInfo, cloudScreenState -> Bool in
                if isSelectFolder == true {
                    return true
                }
                
                if isCloud == false {
                    return false
                }
                
                if cloudScreenState != .empty && cloudScreenState != .hasData {
                    return true
                }
                
                return !(userInfo?.deviceStatus == DeviceStatus.registered ? true : false)
            })
                
        let showPremium = AppManager.shared.eventShouldAddStorePayment
            .filter({$0})
            .do { _ in
                if AppManager.shared.getCurrentScene() == .folder {
                    self.navigator.moveToRegisterPremium()
                    AppManager.shared.eventShouldAddStorePayment.onNext(false)
                }
            }
            .asDriverOnErrorJustComplete().mapToVoid()
        
        return Output(
            title: title,
            openCloudSegment: openCloudSegment,
            hideCreationButton: hideCreationButton,
            hideDismissButton: hideDismissButton,
            createdFolder: createdFolder,
            close: close,
            showPremium: showPremium
        )
    }
}
