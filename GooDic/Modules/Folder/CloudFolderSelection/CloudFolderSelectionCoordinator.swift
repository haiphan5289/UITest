//
//  CloudFolderSelectionCoordinator.swift
//  GooDic
//
//  Created by ttvu on 1/7/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol CloudFolderSelectionNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func dismiss()
    func toCreationFolder(createCloudFolderAsDefault value: Bool) -> Observable<UpdateFolderResult>
}

class CloudFolderSelectionCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?

    var viewController: UIViewController!

    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }

    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = CloudFolderSelectionViewController()
        }
    }

    @discardableResult
    func prepare(delegate: PublishSubject<SelectionResult>, drafts: [Document]) -> CoordinateProtocol {
        createViewControllerIfNeeded()

        guard let vc = viewController as? CloudFolderSelectionViewController else { return self }

        let loginCoord = LoginCoordinator(parentCoord: self)
        loginCoord.prepare(routeLogin: .cloudFolderSelection)
        vc.loginVC = loginCoord.viewController
        
        let errorDeviceCoord = ErrorDeviceRegistrationCoorditator(parentCoord: self)
        errorDeviceCoord.prepare(typeRegister: .cloudFolderSelection)
        vc.devicesVC = errorDeviceCoord.viewController
        
        let viewModel = CloudFolderSelectionViewModel(useCase: CloudFolderSelectionUserCase(),
                                                      navigator: self,
                                                      delegate: delegate,
                                                      drafts: drafts)
        vc.bindViewModel(viewModel)

        return self
    }
}

extension CloudFolderSelectionCoordinator: CloudFolderSelectionNavigateProtocol {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func toCreationFolder(createCloudFolderAsDefault value: Bool) -> Observable<UpdateFolderResult> {
        let delegate = PublishSubject<UpdateFolderResult>()
        
        NamingCoordinator(parentCoord: self)
            .prepare(delegate: delegate,
                     title: L10n.Folder.CreationAlert.title,
                     message: L10n.Folder.CreationAlert.message,
                     confirmButtonName: L10n.Folder.CreationAlert.ok,
                     folder: nil,
                     createCloudFolderAsDefault: value,
                     valueIndex: nil)
            .show()
        
        return delegate
            .asObservable()
    }
}
