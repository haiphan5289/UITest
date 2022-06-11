//
//  GooCloudTableViewController.swift
//  GooDic
//
//  Created by ttvu on 12/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GooCloudTableViewController: GooTableViewController {
    
    struct Constant {
        static let medium: CGFloat = 44
        static let small: CGFloat = 30
    }

    // MARK: - UI
    lazy var refreshControl: GooRefreshControl = {
        let control = GooRefreshControl()
        return control
    }()
    
    private lazy var loadingBackground: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var centerActivityIndicator: GooActivityIndicatorView = {
        let control = GooActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: Constant.medium, height: Constant.medium))
        return control
    }()
    
    lazy var footer: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        view.addSubview(bottomActivityIndicator)
        
        bottomActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bottomActivityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.bottomActivityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            self.bottomActivityIndicator.widthAnchor.constraint(equalToConstant: self.bottomActivityIndicator.bounds.width),
            self.bottomActivityIndicator.heightAnchor.constraint(equalToConstant: self.bottomActivityIndicator.bounds.height)
        ])
        
        return view
    }()
    
    lazy var bottomActivityIndicator: GooActivityIndicatorView = {
        let control = GooActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: Constant.small, height: Constant.small))
        control.color = Asset.textSecondary.color
        
        NSLayoutConstraint.activate([
            control.heightAnchor.constraint(equalToConstant: control.bounds.width),
            control.widthAnchor.constraint(equalToConstant: control.bounds.height)
        ])
        
        return control
    }()
    
    // MARK: - Life cycle
    override func loadView() {
        super.loadView()
        
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        
        self.view.insertSubview(loadingBackground, aboveSubview: self.tableView)
        loadingBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.loadingBackground.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.loadingBackground.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.loadingBackground.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.loadingBackground.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        loadingBackground.isHidden = true
        
        loadingBackground.addSubview(centerActivityIndicator)
        centerActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.centerActivityIndicator.centerXAnchor.constraint(equalTo: loadingBackground.centerXAnchor),
            self.centerActivityIndicator.centerYAnchor.constraint(equalTo: loadingBackground.centerYAnchor),
            self.centerActivityIndicator.widthAnchor.constraint(equalToConstant: self.centerActivityIndicator.bounds.width),
            self.centerActivityIndicator.heightAnchor.constraint(equalToConstant: self.centerActivityIndicator.bounds.height)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }
    
    func getRefreshTrigger() -> Driver<Void> {
        refreshControl.rx.controlEvent(.valueChanged).asDriverOnErrorJustComplete()
    }
    
    func getLoadMoreTrigger() -> Driver<Void> {
        tableView.rx.didScroll
            .map({ [weak self] _ in
                return self?.tableView.isNearBottomEdge() ?? false
            })
            .distinctUntilChanged()
            .filter({ $0 })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
    }
    
    // No.40: The client don't want to show it any more
    func showCenterIndicator(_ show: Bool) {
//        loadingBackground.isHidden = show ? false : true
//        if show {
//            centerActivityIndicator.startAnimating()
//        } else {
//            centerActivityIndicator.stopAnimating()
//        }
    }
}

// MARK: - UITableViewDelegate
extension GooCloudTableViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let value = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        refreshControl.pull(to: value)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        refreshControl.releasePull()
        
        let value = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        if value > 0 {
            scrollView.setContentOffset(.zero, animated: true)
        }
        
    }
}
