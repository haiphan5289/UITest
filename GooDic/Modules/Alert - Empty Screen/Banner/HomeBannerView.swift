//
//  HomeBannerView.swift
//  GooDic
//
//  Created by Nguyen Vu Hao on 14/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

class HomeBannerView: UIView {
    
    static let heightDefault: CGFloat = 56.0
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    var originalContent: String? {
        didSet {
           updateAttributeTitle()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
        closeButton.tintColor = .white
        infoButton.tintColor = .white
        infoButton.setTitle("", for: .normal)
        closeButton.setTitle("", for: .normal)
        closeButton.setImage(Asset.icCloseWhite.image, for: .normal)
        infoButton.setImage(Asset.icInfo.image, for: .normal)
        actionButton.setTitle("", for: .normal)
        
        //ask the system to start notifying when interface change
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(HomeBannerView.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadNib() {
        let nibView = fromNib()
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nibView.topAnchor.constraint(equalTo: self.topAnchor),
            nibView.leftAnchor.constraint(equalTo: self.leftAnchor),
            nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            nibView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    
    @objc private func rotated() {
        updateAttributeTitle()
    }
    
    private func updateAttributeTitle() {
        if UIDevice.current.orientation.isLandscape {
            titleLabel.text = originalContent?.replacingOccurrences(of: "\n", with: "")
        } else if UIDevice.current.orientation.isPortrait {
            titleLabel.text = originalContent
        }
        titleLabel.setLineHeight(lineHeight: 5, paragraphSpacing: 0.0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}
