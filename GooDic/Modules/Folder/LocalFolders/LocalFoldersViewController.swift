//
//  LocalFoldersViewController.swift
//  GooDic
//
//  Created by ttvu on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

class LocalFoldersViewController: BaseViewController, ViewBindableProtocol, FoldersScreenProtocol {
    
    struct Constant {
        static let heightHeader: CGFloat = 51
        static let distanceOffsetToHideHeaderView: CGFloat = 20
    }
    
    // MARK: - UI
    @IBOutlet weak var tableView: UITableView!
    
    var swipeAnchor: UIView? // using to anchor the swipe tooltip
    lazy var tutorialSwipeFolderPopup: UIImageView! = {
        let tutorial = UIImageView(image: Asset.imgTutoFolder.image)
        tutorial.addTapGesture { [weak self] (gesture) in
            self?.interactWithSwipeFolderTutorial.onNext(())
        }
        
        return tutorial
    }()
    
    // MARK: - Rx & Data
    var disposeBag = DisposeBag()
    var viewModel: LocalFoldersViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var deleteAtIndexPath = PublishSubject<IndexPath>()
    var renameAtIndexPath = PublishSubject<IndexPath>()
    var tapUncategorizedFolder = PublishSubject<Void>()
    var interactWithSwipeFolderTutorial = PublishSubject<Void>()
    var viewDidAppearTrigger = PublishSubject<Void>()
    var viewDidLayoutSubviewsTrigger = PublishSubject<Void>()
    private let moveToSort: PublishSubject<Void> = PublishSubject.init()
    private let trackingUserPropertiesSort: PublishSubject<Void> = PublishSubject.init()
    private var sortModel: SortModel = SortModel.valueDefault
    private let saveIndex: PublishSubject<SortModel> = PublishSubject.init()
    private let headerView: UIView = UIView(frame: .zero)
    
    /// FoldersScreenProtocol
    let folderCount = BehaviorSubject<Int>(value: -1) // invalid value
    let didCreateFolder = PublishSubject<UpdateFolderResult>()
    let foldersEvent: BehaviorSubject<[CDFolder]> = BehaviorSubject.init(value: [])
    
    // create this image to custom action's title
    lazy var deleteActionTitleImage: UIImage? = {
        if let cgImage = Asset.icDeletionAction.image.cgImage {
            return ImageWithoutRender(cgImage: cgImage, scale: UIScreen.main.nativeScale, orientation: .up)
        }
        
        return nil
    }()
    
    lazy var renameActionTitleImage: UIImage? = {
        if let cgImage = Asset.icRenameAction.image.cgImage {
            return ImageWithoutRender(cgImage: cgImage, scale: UIScreen.main.nativeScale, orientation: .up)
        }
        
        return nil
    }()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        AppManager.shared.billingInfo.accept(BillingInfo(platform: "", billingStatus: .paid))
        setupUI()
        bindUI()
        self.setupRX()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableView.isEditing = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppearTrigger.onNext(())
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewDidLayoutSubviewsTrigger.onNext(())
    }
    
    // MARK: - Funcs
    func setupUI() {
        // handle tabBar to hide or show, we check a view controller which will be showed
        self.navigationController?.delegate = self
        
        let cellName = String(describing: FolderTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: FolderTVC.reuseIdentifier)
        
        tableView.hideEmptyCells()
        tableView.separatorColor = Asset.cellSeparator.color
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        self.view.addSeparator(at: .top, color: Asset.cellSeparator.color)
    }
    
    func bindUI() {
        tableView.rx
            .setDelegate(self)
            .disposed(by: self.disposeBag)
    }
    
    private func loadData() {
        viewModel.dataSource.setResultsControllerDelegate(frcDelegate: self)
        
        tableView.dataSource = self
        
        tableView.reloadData()
    }
    
    func bindViewModel() {
        loadData()
        
        let updateUITrigger = Driver
            .merge(tableView.endUpdatesEvent.asDriver(),
                   //the first value is default in the method loadData
                   //the second value is the foldersEvent
                   tableView.reloadDataEvent.asDriver().skip(2),
                   viewDidAppearTrigger.asDriverOnErrorJustComplete())
        
        let checkedNewUserTrigger = AppManager.shared.checkedNewUser
            .filter({ $0 })
            .asDriverOnErrorJustComplete()
        
        let input = LocalFoldersViewModel.Input(
            loadTrigger: Driver.just(()),
            viewWillDisAppear: self.rx.viewWillDisappear.asDriverOnErrorJustComplete().mapToVoid(),
            updateUITrigger: updateUITrigger,
            viewDidAppearTrigger: viewDidAppearTrigger.asDriverOnErrorJustComplete(),
            viewDidLayoutSubviewsTrigger: viewDidLayoutSubviewsTrigger.asDriverOnErrorJustComplete(),
            renameAtIndexPath: renameAtIndexPath.asDriverOnErrorJustComplete(),
            deleteAtIndexPath: deleteAtIndexPath.asDriverOnErrorJustComplete(),
            selectAtIndexPath: selectAtIndexPath.asDriverOnErrorJustComplete(),
            selectUncategorizedFolder: tapUncategorizedFolder.asDriverOnErrorJustComplete(),
            interactWithSwipeFolderTutorialTrigger: interactWithSwipeFolderTutorial.asDriverOnErrorJustComplete(),
            checkedNewUserTrigger: checkedNewUserTrigger,
            moveToSort: self.moveToSort.asDriverOnErrorJustComplete(),
            saveIndex: self.saveIndex.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.folderCount
            .drive(onNext: { [weak self] count in
                self?.folderCount.onNext(count)
            })
            .disposed(by: self.disposeBag)
        
        output.renamedFolder
            .drive()
            .disposed(by: self.disposeBag)
        
        output.deletedFolder
            .drive()
            .disposed(by: self.disposeBag)
        
        output.selectedFolder
            .drive(onNext: { [weak self] (_) in
                guard let self = self else { return }
                
                if let indexPaths = self.tableView.indexPathsForVisibleRows {
                    self.tableView.reloadRows(at: indexPaths, with: .automatic)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.showSwipeFolderTutorial
                    .drive(onNext: { [weak self] show in
                        guard let self = self else { return }
                        
                        if show && self.tableView.indexPathsForVisibleRows?.contains(IndexPath(row: 0, section: 1)) == true {
                            if let cell = self.tableView.cellForRow(at: IndexPath(item: 0, section: 1)) {
                                let paddingRight: CGFloat = 10
                                let pointingCornerPaddingRight: CGFloat = 60.0
                                
                                let popupAnchorPoint = CGPoint(x: self.tutorialSwipeFolderPopup.bounds.width - pointingCornerPaddingRight, y: 0)
                                let targetAnchorPoint = CGPoint(x: cell.frame.width - pointingCornerPaddingRight - paddingRight, y: cell.frame.maxY)
                                
                                if self.swipeAnchor == nil {
                                    self.swipeAnchor = UIView(frame: CGRect(origin: targetAnchorPoint, size: .zero))
                                    self.tableView.addSubview(self.swipeAnchor!)
                                    self.swipeAnchor?.translatesAutoresizingMaskIntoConstraints = false
                                    
                                    NSLayoutConstraint.activate([
                                        self.swipeAnchor!.widthAnchor.constraint(equalToConstant: 0),
                                        self.swipeAnchor!.heightAnchor.constraint(equalToConstant: 0),
                                        self.swipeAnchor!.rightAnchor.constraint(equalTo: self.tableView.safeAreaLayoutGuide.rightAnchor, constant: -pointingCornerPaddingRight - paddingRight),
                                        self.swipeAnchor!.topAnchor.constraint(equalTo: self.tableView.topAnchor, constant: targetAnchorPoint.y)
                                    ])
                                }
                                
                                var config = UIView.AnimConfig()
                                config.popupAnchorPoint = UIView.AnchorPoint.anchor(popupAnchorPoint)
                                config.targetAnchorPoint = UIView.AnchorPoint.anchor(targetAnchorPoint)
                                
                                self.tableView.show(popup: self.tutorialSwipeFolderPopup, targetRect: cell.frame, config: config, controlView: self.swipeAnchor!)
                            }
                        } else {
                            self.tableView.dismiss(popup: self.tutorialSwipeFolderPopup, verticalAnim: 0)
                        }
                    })
                    .disposed(by: self.disposeBag)
        
        output.autoHideTooltips
            .drive()
            .disposed(by: self.disposeBag)
        
        output.updateSort.drive { [weak self] sort in
            guard let wSelf = self else { return }
            wSelf.sortModel = sort
            wSelf.tableView.reloadData()
            wSelf.trackingUserPropertiesSort.onNext(())
            switch sort.sortName {
            case .manual:
                wSelf.tableView.setEditing((sort.isActiveManual ?? false), animated: true)
            case .created_at, .free, .title, .updated_at:
                wSelf.tableView.setEditing(false, animated: true)
            }
        }.disposed(by: disposeBag)
        
        output.moveToSort
            .drive()
            .disposed(by: self.disposeBag)
        
        output.reSortUpdateName.drive { [weak self] _ in
            guard let wSelf = self else { return }
            wSelf.viewModel.dataSource.updateFolders()
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)

        output.updateList.drive { [weak self] _ in
            guard let wSelf = self else { return }
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)

        output.hideButton.drive().disposed(by: self.disposeBag)
        
        output.saveFolderEventGreaterThan.drive { [weak self] isSave in
            guard let wSelf = self, let isSave = isSave else { return }
            if isSave {
                wSelf.viewModel.dataSource.sortFolder(isSave: false)
                wSelf.tableView.reloadData()
            }
        }.disposed(by: self.disposeBag)

                
        tracking(output: output)
    }
    
    private func setupRX() {
        self.trackingUserPropertiesSort.asObservable().bind { _ in
            GATracking.sendUserProperties(property: .folderSortOrder(AppSettings.sortModel))
        }.disposed(by: self.disposeBag)
        
        self.viewModel.dataSource.foldersEvent.asObservable().bind { [weak self] list in
            guard let wSelf = self else { return }
            wSelf.foldersEvent.onNext(list)
        }.disposed(by: self.disposeBag)
        
        //to make ensure data will show corectly
        self.viewModel.dataSource.foldersEvent.debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance).bind { [weak self] _ in
            guard let wSelf = self else { return }
            print("========= relaod folder")
            wSelf.viewModel.dataSource.sortFolder(isSave: false)
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)
    }
    
    private func tracking(output: LocalFoldersViewModel.Output) {
        let renameAction = renameAtIndexPath
            .map({ _ in GATracking.Tap.tapChangeFolderName })
        
        let deleteAction = deleteAtIndexPath
            .map({ _ in GATracking.Tap.tapRemoveFolder })
        
        Observable.merge(renameAction, deleteAction)
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
    }
    
    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let folder = viewModel.dataSource.folder(at: indexPath)
        let folderCell = cell as! FolderTVC
        
        if folder.id == .local("") {
            folderCell.bind(data: folder, iconImage: Asset.icOsLocalFolder.image, type: .none)
        } else {
            folderCell.bind(data: folder, iconImage: Asset.icLocalFolder.image, type: .none)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
    }
}

// MARK: - UITableViewDataSource
extension LocalFoldersViewController: UITableViewDataSource {
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
extension LocalFoldersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return Constant.heightHeader
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        self.headerView.subviews.forEach { sub in
            sub.removeFromSuperview()
        }
        let img: UIImageView = UIImageView(frame: .zero)
        img.image = AppManager.shared.imageSort(sortModel: self.sortModel)
        
        self.headerView.addSubview(img)
        img.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            img.leftAnchor.constraint(equalTo: self.headerView.leftAnchor, constant: 20),
            img.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor, constant: 0)
        ])
        
        let bt: UIButton = UIButton(frame: .zero)
        self.headerView.addSubview(bt)
        bt.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bt.leftAnchor.constraint(equalTo: self.headerView.leftAnchor, constant: 0),
            bt.rightAnchor.constraint(equalTo: self.headerView.rightAnchor, constant: 0),
            bt.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: 0),
            bt.topAnchor.constraint(equalTo: self.headerView.topAnchor, constant: 0)
        ])
        
        let lineView: UIView = UIView(frame: .zero)
        lineView.backgroundColor = Asset.cellSeparator.color
        
        self.headerView.addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineView.leftAnchor.constraint(equalTo: self.headerView.leftAnchor, constant: 0),
            lineView.rightAnchor.constraint(equalTo: self.headerView.rightAnchor, constant: 0),
            lineView.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: 0),
            lineView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        bt.rx.tap.bind { _ in
            switch self.sortModel.sortName {
            case .manual:
                if (self.sortModel.isActiveManual ?? false) {
                    let sort: SortModel = SortModel(sortName: self.sortModel.sortName, asc: self.sortModel.asc, isActiveManual: false)
                    self.saveIndex.onNext(sort)
                } else {
                    self.moveToSort.onNext(())
                    GATracking.tap(.tapFolderSortMenu)
                }
            case .created_at, .free, .title, .updated_at:
                self.moveToSort.onNext(())
                GATracking.tap(.tapFolderSortMenu)
            }
            
        }.disposed(by: self.disposeBag)
        
        return self.headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectAtIndexPath.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        interactWithSwipeFolderTutorial.onNext(())
        
        let deletionAction = UIContextualAction(style: .normal, title: nil) { [unowned self] (ac, view, success) in
            self.deleteAtIndexPath.onNext(indexPath)
            success(true)
        }
        deletionAction.image = deleteActionTitleImage
        deletionAction.backgroundColor = Asset.deletionAction.color
        
        let renameAction = UIContextualAction(style: .normal, title: nil) { [unowned self] (ac, view, success) in
            self.renameAtIndexPath.onNext(indexPath)
            success(true)
        }
        renameAction.image = renameActionTitleImage
        renameAction.backgroundColor = Asset.pushBackAction.color

        let swipeAction = UISwipeActionsConfiguration(actions: [deletionAction, renameAction])
        swipeAction.performsFirstActionWithFullSwipe = false
        
        return swipeAction
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard let cell = tableView.cellForRow(at: sourceIndexPath) else {
            return proposedDestinationIndexPath
        }
        cell.backgroundColor = Asset.ffffff121212.color
        cell.alpha = 1
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath else { return }
        
        let place = self.viewModel.dataSource.folders[sourceIndexPath.row]
        self.viewModel.dataSource.folders.remove(at: sourceIndexPath.row)
        self.viewModel.dataSource.folders.insert(place, at: destinationIndexPath.row)
        tableView.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= Constant.distanceOffsetToHideHeaderView {
            self.headerView.isHidden = true
        } else {
            self.headerView.isHidden = false
        }
        
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension LocalFoldersViewController: NSFetchedResultsControllerDelegate {
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

// MARK: - UINavigationControllerDelegate
extension LocalFoldersViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // only show tabBar if viewController is DraftListViewController or FolderBrowserViewController
//        self.tabBarController?.tabBar.isHidden = !(viewController is DraftListViewController || viewController is FolderViewController)
    }
}
