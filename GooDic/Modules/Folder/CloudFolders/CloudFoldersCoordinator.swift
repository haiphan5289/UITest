//
//  CloudFoldersCoordinator.swift
//  GooDic
//
//  Created by ttvu on 1/7/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol CloudFoldersNavigateProtocol: ErrorMessageProtocol, AuthenticationNavigateProtocol {
    func toRenameFolder(folder: Folder) -> Observable<UpdateFolderResult>
    func toDraftList(in folder: Folder?)
    func toConfirmationDeletion() -> Observable<Bool>
    var updateSort: PublishSubject<SortModel> { get }
    func moveToSort(sortModel: SortModel)
}

class CloudFoldersCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    var viewController: UIViewController!
    private let updateSortOb: PublishSubject<SortModel> = PublishSubject.init()
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = CloudFoldersViewController()
        }
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        createViewControllerIfNeeded()

        guard let vc = viewController as? CloudFoldersViewController else { return self }

        let loginCoord = LoginCoordinator(parentCoord: self)
        loginCoord.prepare(routeLogin: .cloudFolder)
        vc.loginVC = loginCoord.viewController
        
        let errorDeviceCoord = ErrorDeviceRegistrationCoorditator(parentCoord: self)
        errorDeviceCoord.prepare(typeRegister: .cloudFolder)
        vc.devicesVC = errorDeviceCoord.viewController
        
        let viewModel = CloudFoldersViewModel(useCase: CloudFoldersUseCase(),
                                              navigator: self)
        vc.bindViewModel(viewModel)

        return self
    }
    
    func getViewModelCloud() -> CloudFoldersViewModel {
        let vc = viewController as! CloudFoldersViewController
        return vc.viewModel
    }
}

extension CloudFoldersCoordinator: CloudFoldersNavigateProtocol {
    
    var updateSort: PublishSubject<SortModel> {
        return self.updateSortOb
    }
    
    func toRenameFolder(folder: Folder) -> Observable<UpdateFolderResult> {
        let delegate = PublishSubject<UpdateFolderResult>()
        
        NamingCoordinator(parentCoord: self)
            .prepare(delegate: delegate,
                     title: L10n.Folder.RenameAlert.title,
                     message: L10n.Folder.RenameAlert.message,
                     confirmButtonName: L10n.Folder.RenameAlert.ok,
                     folder: folder, valueIndex: nil)
            .show()
        
        return delegate
            .asObservable()
    }
    
    func toDraftList(in folder: Folder?) {
        let coord = DraftsCoordinator(parentCoord: self)
        
        if let nc = viewController.navigationController, nc.viewControllers.count > 1 {
            nc.popToRootViewController(animated: false)
        }
        
        if let folder = folder {
            coord.prepare(folder: folder)
                .push()
        } else {
            coord.prepare(folder: Folder(name: L10n.Folder.uncategorized, id: .local(""), manualIndex: nil, hasSortManual: false))
                .push()
        }
    }
    
    func toConfirmationDeletion() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Folder.CreationAlert.cancel, style: .default),
            .action(title: L10n.Folder.ConfirmationAlert.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == L10n.Folder.ConfirmationAlert.ok {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.cancel.color, forKey: "titleTextColor")
            }
        }
        
        return UIAlertController
            .present(in: viewController,
                     title: L10n.Folder.ConfirmationAlert.title,
                     message: L10n.Folder.ConfirmationAlert.message,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
    
    func moveToSort(sortModel: SortModel) {
        let draw = DrawPresentCoodinator(parentCoord: self)
        draw.delegate = self
        draw.prepare(openfromScreen: .folderCloud, sortModel: sortModel, folder: nil).presentInNavigationController()
    }
    
}
extension CloudFoldersCoordinator: DrawPresentDelegate {
    
    func updateSort(sort: SortModel) {
        self.updateSortOb.onNext(sort)
    }
    
    func dismissSort() {
    }
}
