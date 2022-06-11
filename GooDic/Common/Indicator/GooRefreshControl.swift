//
//  GooRefreshControl.swift
//  GooDic
//
//  Created by ttvu on 12/28/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class GooRefreshControl: UIRefreshControl {
    enum RefreshState {
        case none
        case pulling
        case refreshing
        case release
    }
    
    struct Constant {
        static let height: CGFloat = 44.0
        static let pullDistance: CGFloat = 88.0
    }
    
    fileprivate var refreshContainerView: Indicator!
    fileprivate var refreshState: RefreshState = .none
    
    override init() {
        super.init()
        
        // to make the default indicator be visible
        self.tintColor = .clear
        self.subviews.first?.alpha = 0
        
        setupRefreshControl()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupRefreshControl() {
        refreshContainerView = Indicator(frame: CGRect(x: 0, y: 0, width: Constant.height, height: Constant.height))
        
        addSubview(self.refreshContainerView)
        
        refreshContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refreshContainerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            refreshContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            refreshContainerView.widthAnchor.constraint(equalToConstant: Constant.height),
            refreshContainerView.heightAnchor.constraint(equalToConstant: Constant.height)
        ])
    }
    
    func pull(to value: CGFloat) {
        if refreshState == .none {
            refreshState = .pulling
        }
        
        if self.refreshState == .pulling {
            let percent = value < 0 ? 0 : value / Constant.pullDistance
            refreshContainerView.pull(to: percent)
        }
        
        if self.refreshState == .release && self.isRefreshing == false {
            refreshContainerView.stopAnim()
            self.refreshState = .none
        }
    }
    
    func releasePull() {
        refreshState = .release
    }
    
    override func beginRefreshing() {
        refreshState = .refreshing
        refreshContainerView.startAnim()
        super.beginRefreshing()
    }
    
    override func endRefreshing() {
        if self.refreshState == .release {
            refreshContainerView.stopAnim()
            self.refreshState = .none
        }
        
        super.endRefreshing()
    }
}

