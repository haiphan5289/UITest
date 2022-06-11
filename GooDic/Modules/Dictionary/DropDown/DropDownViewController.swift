//
//  DropDownViewController.swift
//  GooDic
//
//  Created by ttvu on 9/8/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class DropDownViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var data: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
    }
    
    func setupUI() {
        let cellName = String(describing: DropDownTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: DropDownTVC.reuseIdentifier)
        
        tableView.hideEmptyCells()
        
        tableView.estimatedRowHeight = 48
        tableView.separatorColor = Asset.dictCellSeparator.color
    }
    
}

extension DropDownViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DropDownTVC.reuseIdentifier, for: indexPath) as! DropDownTVC
        
        cell.bind(data: data[indexPath.row])
        
        return cell
    }
}
