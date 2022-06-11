//
//  CloudDraftsCoordinator.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol CloudDraftsNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func toDocument(_ document: Document)
    func toFolderSelection(drafts: [Document], draftOrigin: [Document]) -> Observable<Folder>
    func toFolder(folder: Folder)
    func toReferenceView(_ document: Document)
    func moveToSort(sortModel: SortModel, folder: Folder?)
    var updateSort: PublishSubject<SortModel> { get }
    var reloadCloudDraftsTrigger: PublishSubject<Void> { get set }
}

class CloudDraftsCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    private let updateSortOb: PublishSubject<SortModel> = PublishSubject.init()
    
    var reloadCloudDraftsTrigger: PublishSubject<Void> = PublishSubject.init()

    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    @discardableResult
    func prepare(folder: Folder?) -> CoordinateProtocol {
        viewController = CloudDraftsViewController()
        
        guard let vc = viewController as? CloudDraftsViewController else {
            return self
        }
        
        let loginCoord = LoginCoordinator(parentCoord: self)
        loginCoord.prepare(routeLogin: .cloudDraft)
        vc.loginVC = loginCoord.viewController
        
        let errorDeviceCoord = ErrorDeviceRegistrationCoorditator(parentCoord: self)
        if folder != nil { // at folder
            errorDeviceCoord.prepare(typeRegister: .cloudDraft, paddingTop: 34) // 34 px is based on design
        } else { // at home
            errorDeviceCoord.prepare(typeRegister: .cloudDraft)
        }
        vc.devicesVC = errorDeviceCoord.viewController
        
        let useCase = CloudDraftsUseCase()
        let viewModel = CloudDraftsViewModel(navigator: self, useCase: useCase, folder: folder)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension CloudDraftsCoordinator: CloudDraftsNavigateProtocol {
    var updateSort: PublishSubject<SortModel> {
        return self.updateSortOb
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
    
    func toReferenceView(_ document: Document) {
        let vc = ReferenceViewController.instantiate(storyboard: .home)
        vc.sceneType = .reference
        vc.document = document
        
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    func moveToSort(sortModel: SortModel, folder: Folder?) {
        let draw = DrawPresentCoodinator(parentCoord: self)
        draw.delegate = self
        draw.prepare(openfromScreen: .draftsCloud, sortModel: sortModel, folder: folder).presentInNavigationController()
    }
}
extension CloudDraftsCoordinator: DrawPresentDelegate {
    
    func updateSort(sort: SortModel) {
        self.updateSortOb.onNext(sort)
    }
    
    func dismissSort() {
    }
}

extension CloudDraftsCoordinator: CreationCoordinatorProtocol {
    func saveDraftType(type: SavingType) {
        
    }
    
    func reloadCloudDrafts() {
        self.reloadCloudDraftsTrigger.onNext(())
    }
}
