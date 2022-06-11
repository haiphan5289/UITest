//
//  GooTableViewController.swift
//  GooDic
//
//  Created by ttvu on 12/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class GooTableViewController: BaseViewController {

    // MARK: - UI
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.backgroundColor = UIColor.clear
        stack.axis = .vertical
        return stack
    }()
    
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorInset = .zero
        tv.separatorColor = Asset.cellSeparator.color
        return tv
    }()
    
    // MARK: - Life cycle
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = Asset.background.color
        
        self.view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setupStackViewConstraints()
        
        stackView.addArrangedSubview(tableView)
    }
    
    func setupStackViewConstraints() {
        NSLayoutConstraint.activate([
            self.view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: stackView.rightAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}
