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
    func toCreationFolder(createCloudFolderAsDefault value: Bool)
    func toDevicesScreen()
}

extension CloudFolderSelectionNavigateProtocol {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func toCreationFolder(createCloudFolderAsDefault value: Bool) {
        NamingCoordinator(parentCoord: self)
            .prepare(title: L10n.Folder.CreationAlert.title,
                     message: L10n.Folder.CreationAlert.message,
                     confirmButtonName: L10n.Folder.CreationAlert.ok,
                     folder: nil,
                     createCloudFolderAsDefault: value)
            .show()
    }
    
    func toDevicesScreen() {
        RegisterDeviceCoordinator(parentCoord: self)
            .prepare(typeRegister: .other)
            .push()
    }
}

class CloudFolderSelectionCoordinator: CoordinateProtocol, CloudFolderSelectionNavigateProtocol {
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
    func prepare(delegate: ReplaySubject<[Folder?]>) -> CoordinateProtocol {
        createViewControllerIfNeeded()

        guard let vc = viewController as? CloudFolderSelectionViewController else { return self }

        let viewModel = CloudFolderSelectionVM(useCase: FolderUseCase(),
                                               navigator: self,
                                               delegate: delegate)
        vc.bindViewModel(viewModel)

        return self
    }
}
