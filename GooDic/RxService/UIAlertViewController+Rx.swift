//
//  UIAlertViewController+Rx.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UnselectableTappableTextView: UITextView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }
        
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
}

struct AlertAction {
    var title: String?
    var style: UIAlertAction.Style

    static func action(title: String?, style: UIAlertAction.Style = .default) -> AlertAction {
        return AlertAction(title: title, style: style)
    }
}

extension UIAlertController {
    static func present(in viewController: UIViewController, title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction]) -> Observable<Int> {
        return present(in: viewController, title: title, message: message, style: style, actions: actions, cosmeticBlock: nil)
    }
    
    static func present(in viewController: UIViewController, title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction], cosmeticBlock: ((UIAlertAction) -> Void)? ) -> Observable<Int> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

            actions.enumerated().forEach { index, action in
                let uiAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    observer.onCompleted()
                }
                
                cosmeticBlock?(uiAction)
                
                alertController.addAction(uiAction)
            }

            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .subscribeOn(MainScheduler.instance)
    }
    
    static func presentAutoReShowAlert(in viewController: UIViewController, title: String?, message: NSAttributedString?, style: UIAlertController.Style, actions: [AlertAction], cosmeticBlock: ((UIAlertAction) -> Void)? ) -> Observable<Int> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: "", preferredStyle: style)
            alertController.setValue(message, forKey: "attributedMessage")
            actions.enumerated().forEach { index, action in
                let uiAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    viewController.present(alertController, animated: true, completion: nil)
                }
                cosmeticBlock?(uiAction)
                alertController.addAction(uiAction)
            }
            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create{ alertController.dismiss(animated: true, completion: nil) }
        }
        .subscribeOn(MainScheduler.instance)
    }
    
    static func present(in viewController: UIViewController, title: String?, message: NSAttributedString?, style: UIAlertController.Style, actions: [AlertAction], cosmeticBlock: ((UIAlertAction) -> Void)? ) -> Observable<Int> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: "", preferredStyle: style)

            alertController.setValue(message, forKey: "attributedMessage")
            
            actions.enumerated().forEach { index, action in
                let uiAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    observer.onCompleted()
                }

                cosmeticBlock?(uiAction)

                alertController.addAction(uiAction)
            }

            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .subscribeOn(MainScheduler.instance)
    }
    
    static func present(in viewController: UIViewController, title: String?, clickableMessage: NSAttributedString?, style: UIAlertController.Style, actions: [AlertAction], cosmeticBlock: ((UIAlertAction) -> Void)? ) -> Observable<Int> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: "", preferredStyle: style)
            
            let textView = UnselectableTappableTextView()
            textView.backgroundColor = UIColor.clear
            textView.isEditable = false
            textView.tintColor = Asset.blueHighlight.color
            textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            textView.textContainerInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            textView.textAlignment = .center
            
            let controller = UIViewController()
            textView.frame = controller.view.frame
            controller.view.addSubview(textView)
            
            alertController.setValue(controller, forKey: "contentViewController")
            textView.attributedText = clickableMessage
            
            let font = clickableMessage?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            
            let expectedHeight = clickableMessage?.string
                .expectedHeight(withWidth: 190, font: font ?? textView.font!) ?? 0
            
            let height: NSLayoutConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: expectedHeight + 95)
            alertController.view.addConstraint(height)
            
            actions.enumerated().forEach { index, action in
                let uiAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    observer.onCompleted()
                }
                
                cosmeticBlock?(uiAction)
                
                alertController.addAction(uiAction)
            }

            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .subscribeOn(MainScheduler.instance)
    }
    
    static func present(in viewController: UIViewController, title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction], setupTextFields: @escaping ((inout UIAlertController) -> Void), cosmeticBlock: ((UIAlertAction) -> Void)? = nil) -> Observable<(Int,[String])> {
        return Observable.create { observer in
            var alertController = UIAlertController(title: title, message: message, preferredStyle: style)

            setupTextFields(&alertController)
            
            actions.enumerated().forEach { index, action in
                let uiAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    let list = alertController.textFields?.map({ $0.text ?? "" }) ?? []
                    observer.onNext((index, list))
                    observer.onCompleted()
                }
                
                cosmeticBlock?(uiAction)
                
                alertController.addAction(uiAction)
            }

            viewController.present(alertController, animated: true, completion: nil)
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .subscribeOn(MainScheduler.instance)
    }
}
