//
//  GDProgressView.swift
//  GooDic
//
//  Created by ttvu on 5/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

@objc protocol GDProgressViewDelegate: class {
    @objc optional func progressView(_ progressView: GDProgressView, didChange state: ProgressState)
}

@objc public enum ProgressState: Int {
    case hide
    case loading
    case success
}

@objc class GDProgressView: UIView {
    struct Constant {
        static let quickDuration: TimeInterval = 0.1
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var searchStatusView: UIView!
    @IBOutlet weak var resultStatusView: UIView!
    
    // Do not set isHidden:true if it is already true (This is UIStackView's bug)
    // http://www.openradar.me/25087688
    var state: ProgressState = .hide {
        didSet {
            if oldValue != state {
                switch state {
                case .hide: hide()
                case .loading: show()
                case .success: success()
                }
                
                delegate?.progressView?(self, didChange: state)
            }
        }
    }
    
    weak var delegate: GDProgressViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadNib()
    }
    
    private func loadNib() {
        let nibView = fromNib()
        self.addSubview(nibView)
        
        progressView.progress = 0
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nibView.topAnchor.constraint(equalTo: self.topAnchor),
            nibView.leftAnchor.constraint(equalTo: self.leftAnchor),
            nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            nibView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    
    private func show(time: TimeInterval = 1, toPercent: Float = 0.9, isAutoHide: Bool = false) {
        self.searchStatusView.alpha = 1
        // quick animation
        self.isHidden = false
        self.progressView.setProgress(toPercent, animated: true)
        
        if isAutoHide {
            perform(#selector(autoHide), with: nil, afterDelay: time)
        }
    }
    
    private func success() {
        self.searchStatusView.alpha = 0
        self.progressView.progress = 0
    }
    
    private func hide() {
        self.isHidden = true
        self.progressView.progress = 0
    }
    
    @objc private func autoHide() {
        hide()
    }
}
