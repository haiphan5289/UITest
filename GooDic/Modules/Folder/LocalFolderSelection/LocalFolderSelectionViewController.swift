//
//  LocalFolderSelectionViewController.swift
//  GooDic
//
//  Created by ttvu on 11/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData


class LocalFolderSelectionViewController: BaseViewController, ViewBindableProtocol, FoldersScreenProtocol {

    // MARK: - UI
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Rx & Data
    var disposeBag = DisposeBag()
    var viewModel: LocalFolderSelectionViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var viewDidAppearTrigger = PublishSubject<Void>()
    
    /// FoldersScreenProtocol
    let folderCount = BehaviorSubject<Int>(value: -1) // invalid value
    let didCreateFolder = PublishSubject<UpdateFolderResult>()
    let foldersEvent: BehaviorSubject<[CDFolder]> = BehaviorSubject.init(value: [])
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindUI()
        
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppearTrigger.onNext(())
    }
    
    // MARK: - Funcs
    func setupUI() {
        let cellName = String(describing: FolderTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: FolderTVC.reuseIdentifier)
        tableView.hideEmptyCells()
        tableView.separatorColor = Asset.cellSeparator.color
        
        self.view.addSeparator(at: .top, color: Asset.cellSeparator.color)
        
        self.setupNavigationTitle(type: .localFolderSelection)
        
        self.tableView.backgroundColor = Asset.cellBackground.color
    }
    
    func bindUI() {
        selectAtIndexPath
            .map ({ [weak self] index -> FolderCellType? in
                guard let wSelf = self else { return nil }
                return wSelf.viewModel.dataSource.dataIndexPath(from: index)
                
            })
            .compactMap { $0 }
            .map({ (data: FolderCellType) -> GATracking.Tap in
                switch data {
                case .addFolder: return .tapCreateNewFolder
                default: return .tapSelectFolderToMoveTo
                }
            })
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
    }
    
    private func loadData() {
        viewModel.dataSource.setResultsControllerDelegate(frcDelegate: self)
        
        tableView.dataSource = self
        
        tableView.reloadData()
    }
    
    func bindViewModel() {
        loadData()
        
        let input = LocalFolderSelectionViewModel.Input(
            loadTrigger: Driver.just(()),
            selectAtIndexPath: selectAtIndexPath.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.createdFolder
            .drive(onNext: { [weak self] result in
                self?.didCreateFolder.onNext(result)
            })
            .disposed(by: self.disposeBag)
        
        output.moved
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loading
            .drive(onNext: { show in
                if show {
                    GooLoadingViewController.shared.show()
                } else {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let folder = viewModel.dataSource.folder(at: indexPath)
        let folderCell = cell as! FolderTVC
        
        let selectable = folder.id != viewModel.disabledFolderId
        
        switch folder.id {
        case .none:
            folderCell.bind(data: folder, iconImage: Asset.icAddNewFolder.image)
            
        case .local(let id):
            if id.isEmpty {
                folderCell.bind(data: folder,
                                iconImage: Asset.icOsLocalFolder.image,
                                type: .unselected,
                                canInteraction: selectable)
            } else {
                folderCell.bind(data: folder,
                                iconImage: selectable ? Asset.icLocalFolder.image : Asset.icOsLocalFolder.image,
                                type: .unselected,
                                canInteraction: selectable)
            }
            
        case .cloud(_):
            // DO NOTHING
            break
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

// MARK: - UITableViewDataSource
extension LocalFolderSelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderTVC.reuseIdentifier, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != 0
    }
}

// MARK: - UITableViewDelegate
extension LocalFolderSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectAtIndexPath.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension LocalFolderSelectionViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let indexPath = self.uiIndexPath(from: indexPath)
        let newIndexPath = self.uiIndexPath(from: newIndexPath)
        self.viewModel.dataSource.updateFolders()
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell, at: indexPath)
                }
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        @unknown default:
            fatalError()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func uiIndexPath(from dataIndexPath: IndexPath?) -> IndexPath? {
        guard let dataIndexPath = dataIndexPath else { return nil }
        
        return IndexPath(row: dataIndexPath.row, section: 1)
    }
}

