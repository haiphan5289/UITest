//
//  ReferenceViewController.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class ReferenceViewController: BaseViewController {
    
    // MARK: - Top View | Title
    @IBOutlet weak var topView: MenuControllerSupportingView! // cosmetic: add separator at bottom
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    
    // MARK: - Data
    var document: Document!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupUI()
        render()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    private func setupUI() {
        topView.addSeparator(at: .bottom, color: Asset.separator.color)
        
        let currentFontStyle = FontManager.shared.currentFontStyle
        
        /// setup title textField
        titleTextField.font = currentFontStyle.getTitleFont()
        
        /// setup text view UI
        contentTextView.font = currentFontStyle.getContentFont()
        contentTextView.textColor = Asset.textPrimary.color
        contentTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 60, right: 16)
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.tintColor = Asset.selectionSecondary.color
        contentTextView.tintColorDidChange()
        
        /// change paragraphStyle and kern of `contentTextView`
        /// don't have to set `paragraphStyle` and `kern` of `contentTextView` 's `textStore` because it's empty now
        contentTextView.typingAttributes = currentFontStyle.getContentAtts(baseOn: contentTextView.typingAttributes)
        
        topView.addTapGesture { [unowned self] (gesture) in
            if self.titleTextField.text?.isEmpty == true {
                return
            }
            
            let menu = UIMenuController.shared
            menu.menuItems = [UIMenuItem(title: L10n.Reference.copyAll, action: #selector(self.copyTitle))]
            menu.arrowDirection = .up
            
            self.topView.becomeFirstResponder()
            if self.topView.canBecomeFirstResponder {
                let start = self.titleTextField.beginningOfDocument
                let end = self.titleTextField.endOfDocument
                let textRange = self.titleTextField.textRange(from: start, to: end) ?? UITextRange()
                let textRect = self.titleTextField.firstRect(for: textRange)
                let targetRect = self.titleTextField.convert(textRect, to: self.topView)
                menu.setTargetRect(targetRect, in: self.topView)
                menu.setMenuVisible(true, animated: true)
            }
        }
        
        self.contentTextView.addTapGesture { [unowned self] (gesture) in
            
            let menu = UIMenuController.shared
            menu.menuItems = [UIMenuItem(title: L10n.Reference.copyAll, action: #selector(self.copyContent))]
            menu.arrowDirection = .down
        }
        
    }
    
    private func render() {
        titleTextField.text = document.title
        contentTextView.text = document.content
    }
    
    @objc func copyTitle() {
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = document.title
    }
    
    @objc func copyContent() {
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = document.content
        
        self.contentTextView.selectedTextRange = nil
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
