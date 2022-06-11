//
//  TextViewWithPlaceholder.swift
//  GooDic
//
//  Created by ttvu on 5/14/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

/// a TextView with a placeholder Label
@IBDesignable
class PlaceholderTextView: UITextViewCustomHighlight {
    
    enum MenuState{
        case other
        case paste
    }
    var currentState : MenuState = .other
    
    /// text of placeholder
    @IBInspectable
    var placeholder: String? {
        didSet {
            placeholderLabel?.text = placeholder
        }
    }
    
    /// text color of placeholder
    @IBInspectable
    var placeholderColor: UIColor = UIColor.lightGray {
        didSet {
            placeholderLabel?.textColor = placeholderColor
        }
    }
    
    /// min height of placeholder
    @IBInspectable
    var estimatedLineHeight: CGFloat = 0 {
        didSet {
            if placeholderLabel != nil {
                layoutSubviews()
            }
        }
    }
    
    /// placeholder
    fileprivate lazy var placeholderLabel: UILabel? = {
        var label = UILabel()
        label.textColor = placeholderColor
        label.text = placeholder
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    override var contentInset: UIEdgeInsets {
        didSet {
            self.layoutIfNeeded()
        }
    }
    
    // MARK: Initialize
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        registerObserver()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Setup placeholder
    func registerObserver() {
        /// don't need to unregister an observer in its dealloc method because the app targets iOS 12.0 and later
        NotificationCenter.default.addObserver(self, selector: #selector(PlaceholderTextView.textDidChangeHandler(notification:)), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        registerObserver()
    }
    
    override var font: UIFont? {
        didSet {
            placeholderLabel?.font = font
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if text.isEmpty {
            // show placeholder
            
            // update font and size
            placeholderLabel?.font = font
            var height: CGFloat = placeholderLabel?.font?.lineHeight ?? 0
            if height < estimatedLineHeight {
                height = estimatedLineHeight
            }
            let expectedDefaultWidth: CGFloat = bounds.size.width - textContainerInset.left - textContainerInset.right
            
            placeholderLabel?.frame = CGRect(x: self.textContainerInset.left, y: self.textContainerInset.top, width: expectedDefaultWidth, height: height)
            
            addSubview(placeholderLabel!)
            bringSubviewToFront(placeholderLabel!)
        } else {
            // hide placehoder
            placeholderLabel?.removeFromSuperview()
        }
    }
    
    @objc func textDidChangeHandler(notification: Notification) {
        layoutSubviews()
    }
    
    // MARK: - Tracking
    override func copy(_ sender: Any?) {
        super.copy(sender)
        
        trackTapOnMenuButton()
    }
    
    override func paste(_ sender: Any?) {
        super.paste(sender)
        
        trackTapOnMenuButton()
    }
    
    override func cut(_ sender: Any?) {
        super.cut(sender)
        
        trackTapOnMenuButton()
    }
    
    override func select(_ sender: Any?) {
        super.select(sender)
        
        trackTapOnMenuButton()
    }
    
    override func selectAll(_ sender: Any?) {
        super.selectAll(sender)
        
        trackTapOnMenuButton()
    }
    
    func trackTapOnMenuButton() {
        GATracking.tap(.tapHandle)
    }
    
    // MARK: Menu Action
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        /// disable `define`, `addShortcut` , and `share` menu item
        
        if action.description == "paste:" {
            self.currentState = .paste
        } else {
            self.currentState = .other
        }
        
        if action.description == "_define:" ||
            action.description == "_addShortcut:" ||
            action.description == "_share:" ||
            action.description == "_translate:" {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    // MARK: Japanese Input Mode
    /// get Japanese Input Mode if it is enabling on the user's device
    var jpTextInputMode: UITextInputMode? = {
        let lang = "ja-JP"
        for mode in UITextInputMode.activeInputModes {
            if let langText = mode.primaryLanguage, langText.localizedStandardContains(lang) {
                return mode
            }
        }
        return nil
    }()
    
    /// override input mode to get japanese input mode first. Using the default instead if it's not availabe.
    override var textInputMode: UITextInputMode? {
        return jpTextInputMode ?? super.textInputMode
    }
}

extension UITextView {
    /// get the name of input mode
    /// Because the `textInputMode` function 's overrided to get Japanese Input Mode, it alway returns 'ja-JP' if Japanese Input Mode is available.
    /// So we need this func to get the name from super.
    var currentInputModeString: String? {
        super.textInputMode?.primaryLanguage
    }
}
