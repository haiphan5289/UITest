//
//  ErrorMessageProtocol.swift
//  GooDic
//
//  Created by ttvu on 12/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol ErrorMessageProtocol{
    var viewController: UIViewController! { get }
    
    /// show an error dialog with a message and an Ok button
    func showMessage(_ message: String) -> Observable<Void>
    func showMessage(from vc: UIViewController, message: String) -> Observable<Void>
    
    /// show an error dialog with the title is the error code, static messate and an Ok button
    func showMessage(errorCode: String) -> Observable<Void>
    func showMessage(errorCode: String, message: String, hyperlink: String, link: String) -> Observable<Void>
    func showMessage(from vc: UIViewController, errorCode: String, message: String, hyperlink: String, link: String) -> Observable<Void>
    
    /// show an error dialog with a message and 2 buttons
    func showConfirmMessage(_ message: String) -> Observable<Bool>
    func showConfirmMessage(_ message: String, noSelection: String, yesSelection: String) -> Observable<Bool>
    func showConfirmMessage(from vc: UIViewController, message: String, noSelection: String, yesSelection: String) -> Observable<Bool>
    
    /// show an error dialog with the title is the error code, static messate which contains a hyperlink and 2 buttons
    func showConfirmMessage(errorCode: String) -> Observable<Bool>
    func showConfirmMessage(errorCode: String, message: String, hyperlink: String, link: String) -> Observable<Bool>
    func showConfirmMessage(errorCode: String, message: String, hyperlink: String, link: String, noSelection: String, yesSelection: String) -> Observable<Bool>
    func showConfirmMessage(from vc: UIViewController, errorCode: String, message: String, hyperlink: String, link: String, noSelection: String, yesSelection: String) -> Observable<Bool>
}

extension ErrorMessageProtocol {
    fileprivate func makeUpText(_ message: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        
        var firstChars = message
        var secondChars = ""
        if message.contains("<red>") {
            let arrText = message.components(separatedBy: "<red>")
            if arrText.count == 2 {
                firstChars = arrText[0]
                secondChars = arrText[1]
            }
        }
        
        var messageText: NSMutableAttributedString
        if #available(iOS 13.0, *) {
            messageText = NSMutableAttributedString(
                string: firstChars,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: UIColor.label,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        } else {
            messageText = NSMutableAttributedString(
                string: firstChars,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        }
        
        if secondChars == "" {
            return messageText
        }
        
        let secondText: NSMutableAttributedString
        if #available(iOS 13.0, *) {
            secondText = NSMutableAttributedString(
                string: secondChars,
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: Asset.highlight.color,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        } else {
            secondText = NSMutableAttributedString(
                string: secondChars,
                attributes: [
                    NSAttributedString.Key.foregroundColor: Asset.highlight.color,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.hiraginoSansW3(size: 14)
                ]
            )
        }
        messageText.append(secondText)
        return messageText
    }
}

// MARK: - Dialog with a message and an Ok button
extension ErrorMessageProtocol {
    func showMessage(_ message: String) -> Observable<Void> {
        showMessage(from: viewController,
                    message: message)
    }
    
    func showMessage(from vc: UIViewController, message: String) -> Observable<Void> {
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
        }
        
        let messageText = makeUpText(message)
        
        return UIAlertController
            .present(in: vc,
                     title: "",
                     message: messageText,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .mapToVoid()
    }
}

// MARK: - Dialog with a title which has an error code, a message and an Ok button
extension ErrorMessageProtocol {
    func showMessage(errorCode: String) -> Observable<Void> {
        showMessage(errorCode: errorCode,
                    message: L10n.Server.Error.Other.message,
                    hyperlink: L10n.Server.Error.Other.hyperlink,
                    link: GlobalConstant.errorInfoURL)
    }
    
    func showMessage(errorCode: String, message: String, hyperlink: String, link: String) -> Observable<Void> {
        showMessage(from: viewController,
                    errorCode: errorCode,
                    message: message,
                    hyperlink: hyperlink,
                    link: link)
    }
    
    func showMessage(from vc: UIViewController, errorCode: String, message: String, hyperlink: String, link: String) -> Observable<Void> {
        let title = L10n.Server.Error.Other.title(errorCode)
        
        let actions: [AlertAction] = [
            .action(title: L10n.Alert.ok, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
        }
        
        let attributedString = makeUpText(message)
        
        if let linkRange = message.range(of: hyperlink) {
            let start = message.distance(from: message.startIndex, to: linkRange.lowerBound)
            let length = message.distance(from: linkRange.lowerBound, to: linkRange.upperBound)
            attributedString.addAttribute(.link, value: link, range: NSRange(location: start, length: length))
        }
        
        return UIAlertController
            .present(in: vc,
                     title: title,
                     clickableMessage: attributedString,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .mapToVoid()
    }
}

// MARK: - Dialog with a message and 2 buttons
extension ErrorMessageProtocol {
    func showConfirmMessage(_ message: String) -> Observable<Bool> {
        showConfirmMessage(message,
                           noSelection: L10n.Alert.cancel,
                           yesSelection: L10n.Alert.ok)
    }
    
    func showConfirmMessage(_ message: String,
                            noSelection: String,
                            yesSelection: String) -> Observable<Bool> {
        showConfirmMessage(from: viewController,
                           message: message,
                           noSelection: noSelection,
                           yesSelection: yesSelection)
    }
    
    func showConfirmMessage(from vc: UIViewController, message: String, noSelection: String, yesSelection: String) -> Observable<Bool> {
        let actions: [AlertAction] = [
            .action(title: noSelection, style: .default),
            .action(title: yesSelection, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == yesSelection {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.cancel.color, forKey: "titleTextColor")
            }
        }
        
        let messageText = makeUpText(message)
        
        return UIAlertController
            .present(in: vc,
                     title: "",
                     message: messageText,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
    
}

// MARK: - Dialog with a title, a message which contains a hyperlink, and 2 buttons
extension ErrorMessageProtocol {
    func showConfirmMessage(errorCode: String) -> Observable<Bool> {
        showConfirmMessage(errorCode: errorCode,
                           message: L10n.Creation.Error.Other.message,
                           hyperlink: L10n.Server.Error.Other.hyperlink,
                           link: GlobalConstant.errorInfoURL,
                           noSelection: L10n.Alert.cancel,
                           yesSelection: L10n.Alert.ok)
    }
    
    func showConfirmMessage(errorCode: String,
                            message: String,
                            hyperlink: String,
                            link: String) -> Observable<Bool> {
        showConfirmMessage(errorCode: errorCode,
                           message: message,
                           hyperlink: hyperlink,
                           link: link,
                           noSelection: L10n.Alert.cancel,
                           yesSelection: L10n.Alert.ok)
    }
    
    func showConfirmMessage(errorCode: String,
                            message: String,
                            hyperlink: String,
                            link: String,
                            noSelection: String,
                            yesSelection: String) -> Observable<Bool> {
        showConfirmMessage(from: viewController,
                           errorCode: errorCode,
                           message: message,
                           hyperlink: hyperlink,
                           link: link,
                           noSelection: noSelection,
                           yesSelection: yesSelection)
    }
    
    func showConfirmMessage(from vc: UIViewController, errorCode: String, message: String, hyperlink: String, link: String, noSelection: String, yesSelection: String) -> Observable<Bool> {
        let title = L10n.Server.Error.Other.title(errorCode)
            
        let actions: [AlertAction] = [
            .action(title: noSelection, style: .default),
            .action(title: yesSelection, style: .default)
        ]
        
        let cosmeticBlock: (UIAlertAction) -> Void = { action in
            if action.title == yesSelection {
                action.setValue(Asset.blueHighlight.color, forKey: "titleTextColor")
            } else {
                action.setValue(Asset.cancel.color, forKey: "titleTextColor")
            }
        }
        
        let attributedString = makeUpText(message)
        
        if let linkRange = message.range(of: hyperlink) {
            let start = message.distance(from: message.startIndex, to: linkRange.lowerBound)
            let length = message.distance(from: linkRange.lowerBound, to: linkRange.upperBound)
            attributedString.addAttribute(.link, value: link, range: NSRange(location: start, length: length))
        }
        
        return UIAlertController
            .present(in: vc,
                     title: title,
                     clickableMessage: attributedString,
                     style: .alert,
                     actions: actions,
                     cosmeticBlock: cosmeticBlock)
            .map({ $0 == 1 })
    }
}
