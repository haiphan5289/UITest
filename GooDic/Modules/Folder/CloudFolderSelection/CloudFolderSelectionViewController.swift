//
//  CloudFolderSelectionViewController.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CloudFolderSelectionViewController: GooCloudTableViewController, ViewBindableProtocol, CloudScreenViewProtocol, FoldersScreenProtocol {
    
    // MARK: - UI
    var loginVC: UIViewController!
    var devicesVC: UIViewController!
    private lazy var errorVC = CloudErrorViewController.instantiate(storyboard: .alert)
    
    // MARK: - Rx & Data
    var disposeBag = DisposeBag()
    var viewModel: CloudFolderSelectionViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    
    /// CloudScreenViewProtocol
    let hasChangedTitle = PublishSubject<String>()
    let state = BehaviorSubject<CloudScreenState>(value: .none)
    
    /// FoldersScreenProtocol
    let folderCount = BehaviorSubject<Int>(value: -1) // invalid value
    let didCreateFolder = PublishSubject<UpdateFolderResult>()
    let foldersEvent: BehaviorSubject<[CDFolder]> = BehaviorSubject.init(value: [])
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindUI()
    }
    
    override func setupStackViewConstraints() {
        NSLayoutConstraint.activate([
            self.view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
            self.view.rightAnchor.constraint(equalTo: stackView.rightAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    // MARK: - Funcs
    func setupUI() {
        let cellName = String(describing: FolderTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: FolderTVC.reuseIdentifier)
        
        tableView.hideEmptyCells()
        
        self.view.addSeparator(at: .top, color: Asset.cellSeparator.color)
        
        self.view.backgroundColor = Asset.cellBackground.color
        self.tableView.backgroundColor = Asset.cellBackground.color
        self.devicesVC.view.backgroundColor = Asset.cellBackground.color
        self.loginVC.view.backgroundColor = Asset.cellBackground.color
        self.errorVC.view.backgroundColor = Asset.cellBackground.color
    }
    
    func bindUI() {
        tableView.rx
            .setDelegate(self)
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        errorVC.loadViewIfNeeded()
        devicesVC.loadViewIfNeeded()
        
        let reloadWhenAppear = self.rx.viewDidAppear
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let loadDataTrigger = Driver
            .merge(
                reloadWhenAppear,
                errorVC.refreshButton.rx.tap.asDriver())
        
        let refreshTrigger = getRefreshTrigger()
        let loadMoreTrigger = getLoadMoreTrigger()
        
        let forceReload = NotificationCenter.default.rx
            .notification(.didUpdateCloudFolder)
            .asDriverOnErrorJustComplete()
            .mapToVoid()
        
        let input = CloudFolderSelectionViewModel.Input(
            userInfo: AppManager.shared.userInfo.asDriver(),
            loadDataTrigger: loadDataTrigger,
            refreshTrigger: refreshTrigger,
            loadMoreTrigger: loadMoreTrigger,
            forceReload: forceReload,
            viewWillAppear: self.rx.viewWillAppear.asDriver().mapToVoid(),
            viewDidAppear: self.rx.viewDidAppear.asDriver().mapToVoid(),
            selectAtIndexPath: selectAtIndexPath.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.cellDatas
            .drive(self.tableView.rx.items(cellIdentifier: FolderTVC.reuseIdentifier, cellType: FolderTVC.self),
                   curriedArgument: { index, model, cell in
                    var icon: UIImage
                    switch model.id {
                    case .cloud(let id):
                        icon = id.isEmpty ? Asset.icOsCloudFolder.image : Asset.icCloudFolder.image
                    default:
                        icon = Asset.icAddNewFolder.image
                    }
                    if model.disable == true { icon = Asset.icOsCloudFolder.image }
                    
                    cell.bind(name: model.name, iconImage: icon, canInteraction: !model.disable)
                   })
            .disposed(by: self.disposeBag)
        
        output.createFolder
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
        
        output.error
            .drive()
            .disposed(by: self.disposeBag)
        
        output.isLoading
            .drive(onNext: self.showCenterIndicator(_:))
            .disposed(by: self.disposeBag)
        
        output.isReloading
            .drive(self.refreshControl.rx.isRefreshing)
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
    }
    
    private func updateScreenState(state: CloudScreenState) {
        var view: UIView? = nil
        
        self.state.onNext(state)
        
        switch state {
        case .errorNetwork:
            self.tableView.alpha = 0
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()

            view = self.quickAdd(vc: self.errorVC)
            
        case .notLoggedIn:
            self.tableView.alpha = 0
            self.errorVC.quickRemove()
            self.devicesVC.quickRemove()
            
            view = self.quickAdd(vc: self.loginVC)
            
        case .notRegisterDevice:
            self.tableView.alpha = 0
            self.loginVC.quickRemove()
            self.errorVC.quickRemove()
            
            view = self.quickAdd(vc: self.devicesVC)
            
        case .empty:
            self.tableView.alpha = 1
            
            self.errorVC.quickRemove()
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()
            
        case .hasData:
            self.tableView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.tableView.alpha = 1
            }
            
            self.errorVC.quickRemove()
            self.loginVC.quickRemove()
            self.devicesVC.quickRemove()
            
        case .none:
            self.tableView.alpha = 0
            
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
                view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
        }
    }
}

// MARK: - UITableViewDelegate
extension CloudFolderSelectionViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectAtIndexPath.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
