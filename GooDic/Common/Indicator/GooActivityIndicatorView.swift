//
//  GooActivityIndicatorView.swift
//  GooDic
//
//  Created by ttvu on 12/28/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class GooActivityIndicatorView: UIActivityIndicatorView {
    private var indicator: Indicator!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // to make the default indicator be visible
        self.tintColor = .clear
        self.subviews.first?.alpha = 0
        
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.indicator = Indicator(frame: self.bounds)

        self.addSubview(indicator)

        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(equalTo: self.topAnchor),
            indicator.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            indicator.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            indicator.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    override func startAnimating() {
        super.startAnimating()
        indicator.startAnim()
    }
    
    override func stopAnimating() {
        super.stopAnimating()
        indicator.stopAnim()
    }
}
