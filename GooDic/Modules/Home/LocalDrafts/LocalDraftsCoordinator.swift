//
//  LocalDraftsCoordinator.swift
//  GooDic
//
//  Created by ttvu on 12/16/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol LocalDraftsNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func toDocument(_ document: Document)
    func toFolderSelection(drafts: [Document], draftOrigin: [Document]) -> Observable<Folder>
    func toFolder(folder: Folder)
    func moveToSort(sortModel: SortModel)
    var updateSort: PublishSubject<SortModel> { get }
    var saveDraftType: PublishSubject<SavingType> { get }
}

class LocalDraftsCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    private let updateSortOb: PublishSubject<SortModel> = PublishSubject.init()
    private let saveDraftTypeOb: PublishSubject<SavingType> = PublishSubject.init()
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = LocalDraftsViewController.instantiate(storyboard: .home)
        }
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? LocalDraftsViewController else { return self }
        
        vc.sceneType = .unknown // LocalDraftsViewController is used as a component
        let useCase = LocalDraftsUseCase(query: .none)
        let viewModel = LocalDraftsViewModel(navigator: self, useCase: useCase, folder: nil)
        vc.bindViewModel(viewModel)
        
        return self
    }
    
    @discardableResult
    func prepare(folder: Folder) -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? LocalDraftsViewController else { return self }
        
        vc.sceneType = .draftsInFolder
        let useCase = LocalDraftsUseCase(query: folder.id, folder: folder)
        let title = folder.id == .local("") ? L10n.Folder.uncategorized : folder.name
        let viewModel = LocalDraftsViewModel(navigator: self,
                                             useCase: useCase,
                                             folderId: folder.id,
                                             title: title,
                                             folder: folder)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension LocalDraftsCoordinator: LocalDraftsNavigateProtocol {
    var saveDraftType: PublishSubject<SavingType> {
        return self.saveDraftTypeOb
    }
    
    
    var updateSort: PublishSubject<SortModel> {
           return self.updateSortOb
      }
    
    func moveToSort(sortModel: SortModel) {
           let draw = DrawPresentCoodinator(parentCoord: self)
         draw.delegate = self
        draw.prepare(openfromScreen: .draftsLocal, sortModel: sortModel, folder: nil).presentInNavigationController()
         }

    func toDocument(_ document: Document) {
        let creationCoordinator = CreationCoordinator(parentCoord: self)
        creationCoordinator.delegate = self
        creationCoordinator.prepare(document: document, folder: nil)
            .presentWithNavigationController()
    }
    
    func toFolderSelection(drafts: [Document], draftOrigin: [Document]) -> Observable<Folder> {
        let delegate = PublishSubject<SelectionResult>()
        
        FolderBrowserCoordinator(parentCoord: self)
            .prepare(delegate: delegate, drafts: drafts, draftOrigin: draftOrigin)
            .presentInNavigationController()
        
        return delegate
            .map({ result -> Folder? in
                switch result {
                case .cancel:
                    return nil
                case .done(let folder):
                    return folder
                }
            })
            .compactMap({ $0 })
    }
    
    func toFolder(folder: Folder) {
        var finder = parentCoord
        
        while finder != nil && (finder is MainCoordinator) == false {
            finder = finder?.parentCoord
        }
        
        if let parentCoord = finder as? MainCoordinator {
            parentCoord.toFolder(folder: folder)
        }
    }
}
extension LocalDraftsCoordinator: DrawPresentDelegate {
    func dismissSort() {
        
    }
    
    func updateSort(sort: SortModel) {
        self.updateSortOb.onNext(sort)
    }
    
    
}
extension LocalDraftsCoordinator: CreationCoordinatorProtocol {
    func reloadCloudDrafts() {
        
    }
    
    func saveDraftType(type: SavingType) {
        self.saveDraftTypeOb.onNext(type)
    }
}
