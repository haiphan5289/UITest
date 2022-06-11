//
//  CloudFoldersViewController.swift
//  GooDic
//
//  Created by ttvu on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CloudFoldersViewController: GooCloudTableViewController, ViewBindableProtocol, CloudScreenViewProtocol, FoldersScreenProtocol {
    
    struct Constant {
        static let cellHeight: CGFloat = 50
        static let heightHeader: CGFloat = 51
        static let distanceOffsetToHideHeaderView: CGFloat = 20
    }
    
    // MARK: - UI
    var loginVC: UIViewController!
    var devicesVC: UIViewController!
    private lazy var errorVC = CloudErrorViewController.instantiate(storyboard: .alert)
    private lazy var emptyView: EmptyView = {
        let view = EmptyView(frame: CGRect(origin: .zero, size: EmptyView.minSize))
        view.bind(type: .noCloudFolder)
        view.addSeparator(at: .top, color: Asset.cellSeparator.color)
        
        return view
    }()
    
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
    
    // MARK: - Rx & Data
    var disposeBag = DisposeBag()
    var viewModel: CloudFoldersViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var deleteAtIndexPath = PublishSubject<IndexPath>()
    var renameAtIndexPath = PublishSubject<IndexPath>()
    
    /// CloudScreenViewProtocol
    let hasChangedTitle = PublishSubject<String>()
    let state = BehaviorSubject<CloudScreenState>(value: .none)
    
    /// FoldersScreenProtocol
    let folderCount = BehaviorSubject<Int>(value: -1) // invalid value
    let didCreateFolder = PublishSubject<UpdateFolderResult>()
    let foldersEvent: BehaviorSubject<[CDFolder]> = BehaviorSubject.init(value: [])
    
    private var folders: [Folder] = []
    private var previouslyFolders: [Folder] = []
    private let moveToSort: PublishSubject<Void> = PublishSubject.init()
    private let trackingUserPropertiesSort: PublishSubject<Void> = PublishSubject.init()
    private var sortModel: SortModel = SortModel.valueDefault
    private let saveIndex: PublishSubject<(SortModel, [Folder])> = PublishSubject.init()
    private let headerView: UIView = UIView(frame: .zero)
    private var isEditCell: Bool = false
        
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.bindUI()
        self.setupRX()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableView.isEditing = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - Funcs
    func setupUI() {
        let cellName = String(describing: FolderTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: FolderTVC.reuseIdentifier)
        self.tableView.dataSource = self
        
        self.tableView.hideEmptyCells()
        self.tableView.addSubview(self.refreshControl)
        
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
    
    func bindViewModel() {
        errorVC.loadViewIfNeeded()
        
        let reloadWhenAppear = self.rx.viewDidAppear
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let loadDataTrigger = Driver
            .merge(
                reloadWhenAppear,
                errorVC.refreshButton.rx.tap.asDriver())
            
        let refreshTrigger = getRefreshTrigger()
        let loadMoreTrigger = getLoadMoreTriggerFolderCloud()
        
        let forceReload = NotificationCenter.default.rx
            .notification(.didUpdateCloudFolder)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
            
        let input = CloudFoldersViewModel.Input(
            userInfo: AppManager.shared.userInfo.asDriver(),
            loadDataTrigger: loadDataTrigger,
            refreshTrigger: refreshTrigger,
            loadMoreTrigger: loadMoreTrigger,
            viewWillAppear: self.rx.viewWillAppear.asDriver().mapToVoid(),
            viewDidAppear: self.rx.viewDidAppear.asDriver().mapToVoid(),
            viewDidDisappear: self.rx.viewDidDisappear.asDriver().mapToVoid(),
            viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid(),
            renameAtIndexPath: renameAtIndexPath.asDriverOnErrorJustComplete(),
            deleteAtIndexPath: deleteAtIndexPath.asDriverOnErrorJustComplete(),
            selectAtIndexPath: selectAtIndexPath.asDriverOnErrorJustComplete(),
            forceReload: forceReload,
            moveToSort: self.moveToSort.asDriverOnErrorJustComplete(),
            saveIndex: self.saveIndex.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
//        output.folders
//            .drive(self.tableView.rx.items(cellIdentifier: FolderTVC.reuseIdentifier, cellType: FolderTVC.self),
//                   curriedArgument: { index, model, cell in
//                    let icon: UIImage
//                    switch model.id {
//                    case .cloud(let id):
//                        icon = id.isEmpty ? Asset.icOsCloudFolder.image : Asset.icCloudFolder.image
//                    default:
//                        icon = Asset.icAddNewFolder.image
//                    }
//
//                    cell.bind(name: model.name, iconImage: icon)
//                   })
//            .disposed(by: self.disposeBag)
        
        output.folders.drive(onNext: { [weak self] list in
            guard let wSelf = self else { return }
            wSelf.folders = list
            wSelf.tableView.reloadData()
        }).disposed(by: self.disposeBag)
        
        output.folders
            .map({ $0.count })
            .drive(onNext: { [weak self] count in
                self?.folderCount.onNext(count - 2) // -2: for the two first uncategorized folder
            })
            .disposed(by: self.disposeBag)
        
        output.movedToFolder
            .drive()
            .disposed(by: self.disposeBag)
        
        output.error
            .drive()
            .disposed(by: self.disposeBag)
        
        output.isLoading
            .drive(onNext: self.showCenterIndicator(_:))
            .disposed(by: self.disposeBag)
        
        output.isReloading
            .drive(self.refreshControl.rx.isRefreshing)
            .disposed(by: self.disposeBag)
        
        output.renamedFolder
            .drive()
            .disposed(by: self.disposeBag)
        
        output.deletedFolder
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
        
        output.screenState
            .drive(onNext: { [weak self] state in
                self?.updateScreenState(state: state)
            })
            .disposed(by: self.disposeBag)
        
        output.showBanner
            .drive(onNext: { [weak self] type in
                guard let self = self else { return }
                
                let banner = BannerView(frame: .zero, type: type)
                self.stackView.insertArrangedSubview(banner, at: 0)
            })
            .disposed(by: self.disposeBag)
        
        output.updateSort.drive().disposed(by: self.disposeBag)
        
        output.moveToSort
            .drive()
            .disposed(by: self.disposeBag)
        
        output.sortUpdateEvent.drive { [weak self] sortModel in
            guard let wSelf = self, let isActiveManual = sortModel.isActiveManual  else { return }
            wSelf.sortModel = sortModel
            wSelf.isEditCell = isActiveManual
            wSelf.trackingUserPropertiesSort.onNext(())
            switch sortModel.sortName {
            case .manual:
                wSelf.tableView.setEditing(isActiveManual, animated: true)
                if isActiveManual {
                    wSelf.previouslyFolders = wSelf.folders
                }
                wSelf.tableView.refreshControl = (isActiveManual) ? nil : wSelf.refreshControl
            case .created_at, .free, .title, .updated_at:
                wSelf.tableView.setEditing(false, animated: true)
            }
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
        output.errorWebSettings
            .drive()
            .disposed(by: self.disposeBag)
        
        output.hideButton.drive().disposed(by: self.disposeBag)
        
        output.reUpdateFolders.drive { [weak self] _ in
            guard let wSelf = self else { return }
            wSelf.folders = wSelf.previouslyFolders
            wSelf.tableView.setEditing(false, animated: true)
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
//        output.sortAtEvent.drive().disposed(by: self.disposeBag)
//        
//        output.showexclusiveError.drive().disposed(by: self.disposeBag)
        
//        output.reloadSortedAtFlow.drive().disposed(by: self.disposeBag)

        
        tracking(output: output)
    }
    
    private func setupRX() {
        self.trackingUserPropertiesSort.asObservable().bind { [weak self] _ in
            guard let wSelf = self else { return }
            GATracking.sendUserProperties(property: .cloudFolderSortOrder(wSelf.sortModel))
        }.disposed(by: self.disposeBag)
    }
    
    private func updateScreenState(state: CloudScreenState) {
        var view: UIView? = nil
        
        self.state.onNext(state)
        
        switch state {
        case .errorNetwork:
            self.tableView.alpha = 0
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()
            self.showEmptyView(false)

            view = self.quickAdd(vc: self.errorVC)
            
        case .notLoggedIn:
            self.tableView.alpha = 0
            self.errorVC.quickRemove()
            self.devicesVC.quickRemove()
            self.showEmptyView(false)
            
            view = self.quickAdd(vc: self.loginVC)
            
        case .notRegisterDevice:
            self.tableView.alpha = 0
            self.loginVC.quickRemove()
            self.errorVC.quickRemove()
            self.showEmptyView(false)
            
            view = self.quickAdd(vc: self.devicesVC)
            
        case .empty:
            self.tableView.alpha = 1
            self.showEmptyView(true)
            
            self.errorVC.quickRemove()
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()
            
        case .hasData:
            self.tableView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.tableView.alpha = 1
            }
            self.showEmptyView(false)
            
            self.errorVC.quickRemove()
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()
            
        case .none:
            self.tableView.alpha = 0
            self.showEmptyView(false)
            
            self.errorVC.quickRemove()
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()
        }
        
        if let view = view {
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    }
    
    func getLoadMoreTriggerFolderCloud() -> Driver<Void> {
        tableView.rx.didScroll
            .map({ [weak self] _ in
                guard let wSelf = self else { return false }
                if wSelf.tableView.isEditing {
                    return false
                }
                return self?.tableView.isNearBottomEdge() ?? false
            })
            .distinctUntilChanged()
            .filter({ $0 })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
    }
    
    func tracking(output: CloudFoldersViewModel.Output) {
        let renameAction = renameAtIndexPath
            .map({ _ in GATracking.Tap.tapChangeFolderName })
        
        let deleteAction = deleteAtIndexPath
            .map({ _ in GATracking.Tap.tapRemoveFolder })
        
        Observable.merge(renameAction, deleteAction)
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
    }
    
    private func showEmptyView(_ show: Bool) {
        if show == false {
            tableView.tableFooterView = UIView()
            return
        }

        if tableView.tableFooterView != emptyView {
            tableView.tableFooterView = emptyView
            tableView.layoutIfNeeded()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
    }
}
extension CloudFoldersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FolderTVC.reuseIdentifier, for: indexPath) as! FolderTVC
        if indexPath.row == 0 {
            cell.isEditing = false
        } else {
            cell.isEditing = self.isEditCell
        }
        let model = self.folders[indexPath.row]
        let icon: UIImage
        switch model.id {
        case .cloud(let id):
            icon = id.isEmpty ? Asset.icOsCloudFolder.image : Asset.icCloudFolder.image
        default:
            icon = Asset.icAddNewFolder.image
        }
        cell.bind(name: model.name, iconImage: icon)
        return cell
    }
    
    
}

// MARK: - UITableViewDelegate
extension CloudFoldersViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectAtIndexPath.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        //0: Uncategories
        if indexPath.row == 0 {
            return nil
        }
        
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
}
// MARK: - UITableViewDelegate
extension CloudFoldersViewController {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constant.heightHeader
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
                    self.saveIndex.onNext((sort, self.folders))
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
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        return true
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
        guard sourceIndexPath != destinationIndexPath, sourceIndexPath.row != 0, destinationIndexPath.row != 0 else {
            let place = self.folders[sourceIndexPath.row]
            self.folders.remove(at: sourceIndexPath.row)
            self.folders.insert(place, at: 1)
            tableView.reloadData()
            return
        }
        
        let place = self.folders[sourceIndexPath.row]
        self.folders.remove(at: sourceIndexPath.row)
        self.folders.insert(place, at: destinationIndexPath.row)
        tableView.reloadData()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let value = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        refreshControl.pull(to: value)
        if scrollView.contentOffset.y >= Constant.distanceOffsetToHideHeaderView {
            self.headerView.isHidden = true
        } else {
            self.headerView.isHidden = false
        }
        
    }
}
