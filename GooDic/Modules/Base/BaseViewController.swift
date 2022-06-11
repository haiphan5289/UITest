//
//  BaseViewController.swift
//  GooDic
//
//  Created by ttvu on 6/8/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
#if DEBUG
import RxSwift
#endif

class BaseViewController: UIViewController {
    var sceneType: GATracking.Scene = .unknown
    
    // Use `navigationBarTitle` to expand the title label in case the navigation title is cropped from the top or from the bottom. Ex: "goodic"
    // NOTE: after using this parameter, you can not use the default title any more
    lazy var navigationBarTitle: UILabel = {
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 10))
        
        let label = UILabel(frame: titleView.bounds)
        label.textAlignment = .center
        titleView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            label.heightAnchor.constraint(equalToConstant: 50).setPriority(.defaultLow),
            label.leftAnchor.constraint(equalTo: titleView.leftAnchor),
            label.rightAnchor.constraint(equalTo: titleView.rightAnchor)
        ])
        
        self.navigationItem.titleView = titleView
        
        return label
    }()
    
    /// like the `navigationBarTitle` above but It has a cloud icon at the end
    lazy var navigationBarCloudTitle: UILabel = {
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 10))
        
        let label = UILabel(frame: titleView.bounds)
        label.textAlignment = .center
        titleView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let image = UIImageView(image: Asset.cloud.image)
        titleView.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            label.heightAnchor.constraint(equalToConstant: 50).setPriority(.defaultLow),
            label.leftAnchor.constraint(equalTo: titleView.leftAnchor),
            label.rightAnchor.constraint(equalTo: image.leftAnchor, constant: -5),
            
            image.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            image.rightAnchor.constraint(equalTo: titleView.rightAnchor),
            image.widthAnchor.constraint(equalToConstant: Asset.cloud.image.size.width)
        ])
        
        self.navigationItem.titleView = titleView
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 14.0, *) {
            navigationItem.backButtonTitle = title
            navigationItem.backButtonDisplayMode = .minimal
        } else {
            navigationItem.backButtonTitle = ""
        }
        
//        #if DEBUG
//        print("viewDidLoad \(self.self) resource change \(Resources.total)")
//        #endif
    }
    
//    #if DEBUG
//    deinit {
//        print("deinit \(self.self) resource change \(Resources.total)")
//    }
//    #endif
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        GATracking.map(sceneType, class: self)
    }
    
    // MARK: - Helper funcs
    func createBarButtonItem(with title: String) -> UIBarButtonItem {
        let button = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        button.tintColor = Asset.blueHighlight.color
        return button
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    // Support create attribute string from text
    func attributeStringWith(text: String, paragraphSpacing: CGFloat) -> NSAttributedString {
        let attributeString = NSMutableAttributedString(string: text)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.paragraphSpacing = paragraphSpacing
        style.firstLineHeadIndent = 0
        style.headIndent = 12
        attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSAttributedString.Key.kern, value: 0, range: NSMakeRange(0, attributeString.length))
        return attributeString
    }
}

