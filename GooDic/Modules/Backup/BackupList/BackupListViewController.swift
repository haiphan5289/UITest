//
//  BackupListViewController.swift
//  GooDic
//
//  Created by Vinh Nguyen on 25/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BackupListViewController: GooCloudTableViewController, ViewBindableProtocol {
    
    // MARK: - Rx + Data
    private let disposeBag = DisposeBag()
    var viewModel: BackupListViewModel!
    var backupDocuments: [CloudBackupDocument] = []
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var deselectAtIndexPath = PublishSubject<IndexPath>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
    }

}
extension BackupListViewController {
    
    private func setupUI() {
        navigationController?.navigationBar.tintColor = Asset.textPrimary.color
        self.setupTableView()
    }
    
    private func setupTableView() {
        
        tableView.rowHeight = DocumentTVC.Constant.cellHeight
        tableView.estimatedRowHeight = DocumentTVC.Constant.cellHeight
        tableView.register(BackupListViewCell.nib, forCellReuseIdentifier: SettingAutoCloudSaveViewCell.identifider)
        tableView.separatorStyle = .none
        tableView.hideEmptyCells()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func bindViewModel() {
        
        let refreshTrigger = getRefreshTrigger()
        let loadDataTrigger = self.rx.viewWillAppear
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let input = BackupListViewModel
            .Input(loadDataTrigger: loadDataTrigger,
                   refreshTrigger: refreshTrigger,
                   selectBackupDraftTrigger: tableView.rx.itemSelected.asDriver(),
                   viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid()
                   )
        
        let output = viewModel.transform(input)
        
        output.loadData
            .drive(onNext: {[weak self] data in
                guard let wSelf = self else {
                    return
                }
                wSelf.backupDocuments = data
                wSelf.tableView.reloadData()
            })
            .disposed(by: self.disposeBag)
        
        
        output.openedBackupDraft
            .drive(onNext: { [weak self] _ in
                guard let wSelf = self else { return }
                if let indexPath = wSelf.tableView.indexPathForSelectedRow {
                    wSelf.tableView.deselectRow(at: indexPath, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        
        tracking(output: output)
    }
    
    private func setupRX() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath) in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func tracking(output: BackupListViewModel.Output) {
        // track scene
        GATracking.scene(self.sceneType)
        
        // track tap events
//        output.selectedCell
//            .drive(onNext: { (action) in
//                switch action {
//                case .openSettingBackup:
//                    return
//                default:
//                    return
//                }
//            })
//            .disposed(by: self.disposeBag)
    }
}

// MARK: - UITableViewDataSource
extension BackupListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.backupDocuments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BackupListViewCell.identifider) as? BackupListViewCell else {
            fatalError()
        }
        let model = self.backupDocuments[indexPath.row]
        cell.bind(data: model)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BackupListViewController {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
