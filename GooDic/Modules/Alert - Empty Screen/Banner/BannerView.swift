//
//  BannerView.swift
//  GooDic
//
//  Created by ttvu on 2/8/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

enum BannerType {
    case creation
    case homeCloudDrafts
    case cloudDrafts
    case cloudFolders
    case selectionCloudFolder
    
    var content: String {
        switch self {
        case .creation: return L10n.Banner.saveCloudDraft
        default: return L10n.Banner.pullToRefresh
        }
    }
    
    var isClosed: Bool {
        switch self {
        case .creation: return AppSettings.hideBannerInCreation
        case .homeCloudDrafts: return AppSettings.hideBannerInHomeCloudDrafts
        case .cloudDrafts: return AppSettings.hideBannerInCloudDrafts
        case .cloudFolders: return AppSettings.hideBannerInCloudFolders
        case .selectionCloudFolder: return AppSettings.hideBannerInSelectionCloudFolder
        }
    }
    
    func close() {
        switch self {
        case .creation: AppSettings.hideBannerInCreation = true
        case .homeCloudDrafts: AppSettings.hideBannerInHomeCloudDrafts = true
        case .cloudDrafts: AppSettings.hideBannerInCloudDrafts = true
        case .cloudFolders: AppSettings.hideBannerInCloudFolders = true
        case .selectionCloudFolder: AppSettings.hideBannerInSelectionCloudFolder = true
        }
    }
}

class BannerView: UIView {
    @IBOutlet weak var messageLabel: UILabel!
    
    private(set) var type: BannerType
    
    init(frame: CGRect, type: BannerType) {
        self.type = type
        
        super.init(frame: frame)
        
        loadNib()
        self.messageLabel.text = type.content
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
    
    @IBAction func close(_ sender: Any) {
        type.close()
        UIView.animate(withDuration: 0.3) {
            self.isHidden = true
        }
    }
}

