//
//  LocalFolderSelectionCoordinator.swift
//  GooDic
//
//  Created by ttvu on 1/7/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol LocalFolderSelectionNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func dismiss()
    func toCreationFolder(createCloudFolderAsDefault value: Bool, valueIndex: Double?) -> Observable<UpdateFolderResult>
}

class LocalFolderSelectionCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }

    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = LocalFolderSelectionViewController.instantiate(storyboard: .folder)
        }
    }
    
    @discardableResult
    func prepare(delegate: PublishSubject<SelectionResult>, drafts: [Document], draftOrigin: [Document]) -> CoordinateProtocol {
        createViewControllerIfNeeded()

        guard let vc = viewController as? LocalFolderSelectionViewController else { return self }
        
        let viewModel = LocalFolderSelectionViewModel(useCase: LocalFolderSelectionUseCase(),
                                                      navigator: self,
                                                      delegate: delegate,
                                                      drafts: drafts, draftOrigin: draftOrigin)
        vc.bindViewModel(viewModel)

        return self
    }
    func getViewModelLocal() -> LocalFolderSelectionViewModel {
        let vc = viewController as! LocalFolderSelectionViewController
        return vc.viewModel
    }
}

extension LocalFolderSelectionCoordinator: LocalFolderSelectionNavigateProtocol {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func toCreationFolder(createCloudFolderAsDefault value: Bool, valueIndex: Double?) -> Observable<UpdateFolderResult> {
        let delegate = PublishSubject<UpdateFolderResult>()
        
        NamingCoordinator(parentCoord: self)
            .prepare(delegate: delegate,
                     title: L10n.Folder.CreationAlert.title,
                     message: L10n.Folder.CreationAlert.message,
                     confirmButtonName: L10n.Folder.CreationAlert.ok,
                     folder: nil,
                     createCloudFolderAsDefault: value,
                     valueIndex: valueIndex)
            .show()
        
        return delegate
            .asObservable()
    }
}
