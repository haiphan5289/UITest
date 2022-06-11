//
//  TrashCoordinator.swift
//  GooDic
//
//  Created by ttvu on 10/16/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol TrashNavigateProtocol: ErrorMessageProtocol, AppManagerProtocol {
    func toDeleteAllConfirmationDialog() -> Observable<Bool>
    func toReferenceView(_ document: Document)
    func toDeleteConfirmationDialog() -> Observable<Bool>
}

class TrashCoordinator: CoordinateProtocol {
    var parentCoord: CoordinateProtocol?
    
    weak var viewController: UIViewController!
    
    init(parentCoord: CoordinateProtocol) {
        self.parentCoord = parentCoord
    }
    
    private func createViewControllerIfNeeded() {
        if viewController == nil {
            viewController = TrashViewController.instantiate(storyboard: .home)
        }
    }
    
    @discardableResult
    func prepare() -> CoordinateProtocol {
        createViewControllerIfNeeded()
        guard let vc = viewController as? TrashViewController else { return self }
        
        vc.sceneType = .trash
        let useCase = TrashUseCase()
        let viewModel = TrashViewModel(navigator: self, useCase: useCase)
        vc.bindViewModel(viewModel)
        
        return self
    }
}

extension TrashCoordinator: TrashNavigateProtocol {
    func toDeleteAllConfirmationDialog() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Trash.DeletionAll.cancel, style: .default),
            .action(title: L10n.Trash.DeletionAll.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == L10n.Trash.DeletionAll.ok {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.cancel.color, forKey: "titleTextColor")
            }
        }
        
        return UIAlertController
            .present(in: viewController,
                     title: nil,
                     message: L10n.Trash.DeletionAll.message,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
    
    func toDeleteConfirmationDialog() -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: L10n.Trash.DeletionAll.cancel, style: .default),
            .action(title: L10n.Trash.DeletionAll.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == L10n.Trash.DeletionAll.ok {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.textSecondary.color, forKey: "titleTextColor")
            }
        }
        let messageText = makeUpText(L10n.Trash.Deletion.message)
        return UIAlertController
            .present(in: viewController,
                     title: nil,
                     message: messageText,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
    
    private func makeUpText(_ message: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle

        var messageText: NSMutableAttributedString
        if #available(iOS 13.0, *) {
            messageText = NSMutableAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: UIColor.label,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        } else {
            messageText = NSMutableAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        }
        return messageText
    }
    
    func toReferenceView(_ document: Document) {
        let vc = ReferenceViewController.instantiate(storyboard: .home)
        vc.sceneType = .reference
        vc.document = document
        vc.title = L10n.Trash.title
        
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
