//
//  CloudDraftsViewController.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics
import FirebaseInAppMessaging

class CloudDraftsViewController: GooCloudTableViewController, MultiSelectionViewProtocol, ViewBindableProtocol, CloudScreenViewProtocol {
    
    struct Constant {
        static let cellHeight: CGFloat = 50
        static let heightHeader: CGFloat = 51
        static let distanceOffsetToHideHeaderView: CGFloat = 20
    }
    
    
    var listFolderCloud: PublishSubject<[Folder]> = PublishSubject.init()
    // MARK: - UI
    var loginVC: UIViewController!
    var devicesVC: UIViewController!
    private lazy var errorVC = CloudErrorViewController.instantiate(storyboard: .alert)
    private lazy var emptyView: EmptyView = {
        return EmptyView(frame: CGRect(origin: .zero, size: EmptyView.minSize))
    }()
    
    // swipe tooltip
    var swipeAnchor: UIView? // using to anchor the swipe tooltip
    lazy var tutorialSwipeDocumentPopup: UIImageView = {
        let tutorial = UIImageView(image: Asset.imgTutoDraft.image)
        tutorial.addTapGesture { [weak self] (gesture) in
            self?.interactWithSwipeDocumentTutorial.onNext(())
        }
        
        return tutorial
    }()
    
    // create this image to custom action's title
    lazy var deleteActionTitleImage: UIImage? = {
        if let cgImage = Asset.icDeletionAction.image.cgImage {
            return ImageWithoutRender(cgImage: cgImage, scale: UIScreen.main.nativeScale, orientation: .up)
        }
        
        return nil
    }()
    
    lazy var moveActionTitleImage: UIImage? = {
        if let cgImage = Asset.icMoveAction.image.cgImage {
            return ImageWithoutRender(cgImage: cgImage, scale: UIScreen.main.nativeScale, orientation: .up)
        }
        
        return nil
    }()
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: CloudDraftsViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var deselectAtIndexPath = PublishSubject<IndexPath>()
    var deleteAtIndexPath = PublishSubject<IndexPath>()
    var moveToFolderAtIndexPath = PublishSubject<IndexPath>()
    private var interactWithSwipeDocumentTutorial = PublishSubject<Void>()
    
    /// MultiSelectionViewProtocol
    let editMode = BehaviorSubject(value: false)
    let selectOrDeselectAllItemsTrigger = PublishSubject<Void>()
    let binItemsTrigger = PublishSubject<Void>()
    let moveItemsTrigger = PublishSubject<Void>()
    let selectedItems = BehaviorSubject<[IndexPath]>(value: [])
    let backToNormalModelTrigger = PublishSubject<Void>()
    let selectionButtonTitle = PublishSubject<String>()
    let itemCount = BehaviorSubject<Int>(value: -1) // invalid value
    let showedSwipeDocumentTooltip = PublishSubject<Bool>()
    var eventSelectDraftOver: PublishSubject<Void> = PublishSubject.init()
    var totalSelectDrafts: Int = 0
    
    /// CloudScreenViewProtocol
    let hasChangedTitle = PublishSubject<String>()
    let state = BehaviorSubject<CloudScreenState>(value: .none)
    var documents: [Document] = []
    private var previouslyDocuments: [Document] = []
    private let moveToSort: PublishSubject<Void> = PublishSubject.init()
    private var sortModel: SortModel = SortModel.valueDefaultDraft
    private let saveIndex: PublishSubject<(SortModel, [Document])> = PublishSubject.init()
    private let headerView: UIView = UIView(frame: .zero)
    private var isEditCell: Bool = false
    let hideButtonEventTrigger: PublishSubject<Bool> = PublishSubject.init()
    private var isShowButtonSelect: Bool = false
    private let img: UIImageView = UIImageView(frame: .zero)
    private var isManual: Bool = false
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.bindUI()
        self.tracking()
        self.setupRX()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // the extended actions caches its indexPath as soon as displaying.
        // So if the data of table view is added or removed, it will emit with a wrong indexPath
        // to prevent, we have to hide it before the view has disappeared off the screen
        if self.isEditing == false {
            tableView.isEditing = false
        }
    }
    
    // MARK: - Funcs
    private func setupUI() {
        navigationController?.navigationBar.tintColor = Asset.textPrimary.color
        tableView.rowHeight = DocumentTVC.Constant.cellHeight
        tableView.estimatedRowHeight = DocumentTVC.Constant.cellHeight
        
        let cellName = String(describing: DocumentTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: DocumentTVC.reuseIdentifier)
        
        tableView.hideEmptyCells()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.dataSource = self
        
        setEditing(false, animated: false)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
    }
    
    private func setupEmptyView(with type: EmptyType) {
        emptyView.bind(type: type)
    }
    
    private func showEmptyView(_ show: Bool) {
        if show == false {
            tableView.tableHeaderView = nil
            return
        }
        
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = emptyView
//            emptyView.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                emptyView.heightAnchor.constraint(equalToConstant: 400),
//                emptyView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//                emptyView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
//            ])
//            tableView.sizeToFit()
//            tableView.layoutIfNeeded()
        }
    }
    
    private func bindUI() {
        editMode
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] value in
                guard let self = self else { return }

                if self.isEditing == false && self.tableView.isEditing {
                    // In case you swipe only one row, the table view will be in edit mode, but the view controller is still in normal mode. It makes the table view can't go to edit mode directly. So I have to turn it to normal mode before
                    self.tableView.setEditing(false, animated: false)

                    if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                        self.tableView.reloadRows(at: indexPathsForVisibleRows, with: .none)
                    }
                }

                self.setEditing(value, animated: true)
            })
            .disposed(by: self.disposeBag)

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
        
        let loadMoreTrigger = getLoadMoreTrigger()
        let refreshTrigger = getRefreshTrigger()
        
        let checkedNewUserTrigger = AppManager.shared.checkedNewUser
            .filter({ $0 })
            .asDriverOnErrorJustComplete()
        
        let input = CloudDraftsViewModel.Input(
            userInfo: AppManager.shared.userInfo.asDriver(),
            loadDataTrigger: loadDataTrigger,
            refreshTrigger: refreshTrigger,
            loadMoreTrigger: loadMoreTrigger,
            viewWillAppear: self.rx.viewWillAppear.asDriver().mapToVoid(),
            viewDidAppear: self.rx.viewDidAppear.asDriver().mapToVoid(),
            viewDidDisappear: self.rx.viewDidDisappear.asDriver().mapToVoid(),
            viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid(),
            selectDraftTrigger: selectAtIndexPath.asDriverOnErrorJustComplete(),
            deselectDraftTrigger: deselectAtIndexPath.asDriverOnErrorJustComplete(),
            moveDraftToFolderTrigger: moveToFolderAtIndexPath.asDriverOnErrorJustComplete(),
            binDraftTrigger: deleteAtIndexPath.asDriverOnErrorJustComplete(),
            editingModeTrigger: editMode.asDriverOnErrorJustComplete(),
            selectOrDeselectAllDraftsTrigger: selectOrDeselectAllItemsTrigger.asDriverOnErrorJustComplete(),
            moveSelectedDraftsTrigger: moveItemsTrigger.asDriverOnErrorJustComplete(),
            binSelectedDraftsTrigger: binItemsTrigger.asDriverOnErrorJustComplete(),
            viewDidAppearTrigger: self.rx.viewDidAppear.asDriverOnErrorJustComplete().mapToVoid(),
            viewDidLayoutSubviewsTrigger: self.rx.viewDidLayoutSubviews.asDriverOnErrorJustComplete().mapToVoid(),
            touchSwipeDocumentTooltipTrigger: interactWithSwipeDocumentTutorial.asDriverOnErrorJustComplete(),
            checkedNewUserTrigger: checkedNewUserTrigger,
            moveToSort: self.moveToSort.asDriverOnErrorJustComplete(),
            saveIndex: self.saveIndex.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.emptyViewModel
            .drive(onNext: { [weak self] emptyVM in
                self?.setupEmptyView(with: emptyVM)
            })
            .disposed(by: self.disposeBag)
        
//        output.drafts
//            .drive(
//                self.tableView.rx.items(cellIdentifier: DocumentTVC.reuseIdentifier, cellType: DocumentTVC.self),
//                curriedArgument: { index, model, cell in
//                    cell.bind(title: model.title,
//                              content: model.content,
//                              date: model.updatedAt.toString,
//                              folderName: model.folderName,
//                              onCloud: true)
//                })
//            .disposed(by: self.disposeBag)
        output.drafts.drive { [weak self] drafts in
            guard let wSelf = self else { return }
            wSelf.documents = drafts
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)

        
        output.drafts
            .map({ $0.count > 0 })
            .drive(onNext: { [weak self] hasData in
                guard let self = self else { return }
                self.navigationItem.setRightBarButton(hasData ? self.editButtonItem : nil, animated: false)
            })
            .disposed(by: self.disposeBag)
        
        output.hasChangedTitle
            .drive(onNext: { [weak self] newTitle in
                self?.hasChangedTitle.onNext(newTitle)
            })
            .disposed(by: self.disposeBag)
        
        output.totalDraft
            .drive(onNext: { [weak self] total in
                self?.itemCount.onNext(total)
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
        
        output.isLoadingMore
            .withLatestFrom(output.selectedDrafts, resultSelector: { (isLoading: $0, selectedDrafts: $1) })
            .drive(onNext: { [weak self] (isLoading, selectedDrafts) in
                guard let self = self else { return }
                
                if isLoading {
                    self.tableView.tableFooterView = self.footer
                } else {
                    self.tableView.hideEmptyCells()
                    
                    selectedDrafts.forEach { (indexPath) in
                        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                }
            })
            .disposed(by: self.disposeBag)
        
        output.isLoadingMore
            .drive(self.bottomActivityIndicator.rx.isAnimating)
            .disposed(by: self.disposeBag)

        output.updateSelectedType
            .drive(onNext: { [weak self] type in
                guard let self = self else { return }
                switch type {
                case let .selectAll(total):
                    let indexPaths = (0..<total).map({ IndexPath(row: $0, section: 0) })
                    
                    indexPaths.forEach {
                        self.tableView.selectRow(at: $0, animated: true, scrollPosition: .none)
                    }
                case .unselectAll:
                    let total = self.tableView.numberOfRows(inSection: 0)
                    let indexPaths = (0..<total).map({ IndexPath(row: $0, section: 0) })
                    
                    indexPaths.forEach {
                        self.tableView.deselectRow(at: $0, animated: true)
                    }
                    
                case .normal:
                    break
                }
            })
            .disposed(by: self.disposeBag)

        output.openedDraft
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.showLoading
            .drive(onNext: { show in
                if show {
                    GooLoadingViewController.shared.show()
                } else {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)

        let backToNormalModelWithError = output.screenState
            .filter({ $0 == .notRegisterDevice })
            .mapToVoid()
        
        Driver
            .merge(
                output.movedDraftsToFolder,
                output.binDrafts,
                backToNormalModelWithError)
            .withLatestFrom(output.drafts)
            .map({ $0.count > 0 })
            .drive(onNext: { [weak self] (hasData) in
                guard let self = self else { return }
                
                if let indexPaths = self.tableView.indexPathsForSelectedRows {
                    indexPaths.forEach({ (indexPath) in
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    })
                }
                
                self.setEditing(false, animated: true)
                self.backToNormalModelTrigger.onNext(())

                self.navigationItem.setRightBarButton(hasData ? self.editButtonItem : nil, animated: false)
            })
            .disposed(by: self.disposeBag)

        output.selectedDrafts
            .drive(onNext: { [weak self] value in
                self?.selectedItems.onNext(value)
                self?.totalSelectDrafts = value.count
            })
            .disposed(by: self.disposeBag)
        
        output.selectedDrafts
            .map { (list) -> String in
                let text = (list.count > 0) ? L10n.Draft.BarButtonItem.deselectAll :  L10n.Draft.BarButtonItem.selectAll
                return text
            }
            .drive(onNext: { [weak self] value in
                self?.selectionButtonTitle.onNext(value)
            })
            .disposed(by: self.disposeBag)
        
        output.showSwipeDocumentTooltip
            .drive(onNext: { [weak self] show in
                guard
                    let self = self,
                    let cell = self.tableView.visibleCells.first
                else { return }
                
                self.showedSwipeDocumentTooltip.onNext(show)
                
                if show {
                    // reference to XD file
                    let paddingTop: CGFloat = 4.0
                    let paddingRight: CGFloat = 14.0
                    let pointingCornerPaddingRight: CGFloat = 60.0
                    
                    let popupAnchorPoint = CGPoint(x: self.tutorialSwipeDocumentPopup.bounds.width - pointingCornerPaddingRight, y: 0)
                    let targetAnchorPoint = CGPoint(x: cell.bounds.width - pointingCornerPaddingRight - paddingRight, y: cell.bounds.height + paddingTop)
                    
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
                    
                    self.tableView.show(popup: self.tutorialSwipeDocumentPopup, targetRect: cell.frame, config: config, controlView: self.swipeAnchor!)
                    
                } else {
                    self.tableView.dismiss(popup: self.tutorialSwipeDocumentPopup, verticalAnim: 0)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.autoHideToolTips
            .drive()
            .disposed(by: self.disposeBag)
        
        // to make sure the empty view has been assigned
        Driver.combineLatest(output.screenState, output.emptyViewModel)
            .map({ $0.0 })
            .distinctUntilChanged()
            .drive(onNext: { [weak self] state in
                if self?.stackView.isHidden == true {
                    self?.stackView.isHidden = false
                }
                self?.updateScreenState(state: state)
            })
            .disposed(by: self.disposeBag)
        
        output.showBanner
            .drive(onNext: { [weak self] type in
                guard let self = self else { return }
                
                let banner = BannerView(frame: .zero, type: type)
                self.stackView.insertArrangedSubview(banner, at: 0)
                
                self.stackView.isHidden = true
            })
            .disposed(by: self.disposeBag)
        
        output.moveToSort
            .drive()
            .disposed(by: self.disposeBag)
        
        output.sortUpdateEvent.drive { [weak self] sortModel in
            guard let wSelf = self, let isActiveManual = sortModel.isActiveManual  else { return }
            wSelf.sortModel = sortModel
            wSelf.isEditCell = isActiveManual
            wSelf.tableView.reloadData()
            switch sortModel.sortName {
            case .manual:
                if isActiveManual {
                    wSelf.previouslyDocuments = wSelf.documents
                }
                wSelf.tableView.refreshControl = (isActiveManual) ? nil : wSelf.refreshControl
                wSelf.isManual = isActiveManual
                wSelf.tableView.setEditing(isActiveManual, animated: true)
                wSelf.tableView.allowsMultipleSelectionDuringEditing = !isActiveManual
            case .created_at, .free, .title, .updated_at:
                wSelf.isManual = false
                wSelf.tableView.setEditing(false, animated: true)
                wSelf.tableView.allowsMultipleSelectionDuringEditing = true
            }
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
        //Skip the first valye
        //Onlye get one value
        Observable.combineLatest(output.folder.asObservable(), output.sortUpdateEvent.asObservable()).skip(1).take(1).bind { folder, sort in
            if folder == nil {
                GATracking.sendUserProperties(property: .cloudDraftSortOrder(sort))
            } else {
                GATracking.sendUserProperties(property: .cloudDraftSortOrderFolder(sort))
            }
        }.disposed(by: self.disposeBag)
        
        output.updateSort.drive().disposed(by: self.disposeBag)
        
        output.errorDraftSettings.drive().disposed(by: self.disposeBag)
        
        output.hideButton.drive { [weak self] ishide in
            guard let wSelf = self else { return }
            wSelf.hideButtonEventTrigger.onNext(ishide)
        }.disposed(by: self.disposeBag)
    }
    
    private func setupRX() {
        Observable.merge(NotificationCenter.default.rx.notification(.showTabBar).map({ _ in false }),
                         NotificationCenter.default.rx.notification(.hideTabBar).map({ _ in true }))
            .bind { [weak self] isHide in
                guard let wSelf = self else { return }
                wSelf.isShowButtonSelect = isHide
                if isHide {
                    wSelf.img.image = wSelf.img.image?.withRenderingMode(.alwaysTemplate)
                    wSelf.img.tintColor = Asset.disableSort.color
                } else {
                    wSelf.img.image = AppManager.shared.imageSort(sortModel: wSelf.sortModel)
                    wSelf.img.tintColor = .clear
                }

            }.disposed(by: self.disposeBag)
        
    }
    
    private func tracking() {
        // Tracking Tap events
        let removeAction = deleteAtIndexPath
            .map({ _ in GATracking.Tap.tapRemoveDraft })
        
        let moveToAction = moveToFolderAtIndexPath
            .map({ _ in GATracking.Tap.tapMoveToFolder })
            
        Observable.merge(removeAction, moveToAction)
            .subscribe(onNext: GATracking.tap)
            .disposed(by: self.disposeBag)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
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
}
extension CloudDraftsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DocumentTVC.reuseIdentifier) as? DocumentTVC else {
            fatalError()
        }
        let model = self.documents[indexPath.row]
        cell.isManual = self.isManual
        cell.bind(title: model.title,
                  content: model.content,
                  date: model.updatedAt.toString,
                  folderName: model.folderName,
                  onCloud: true)
        return cell
    }
    
    
}

// MARK: - UITableViewDelegate
extension CloudDraftsViewController {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.documents.count <= 0 {
            return 0
        }
        return Constant.heightHeader
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        self.headerView.subviews.forEach { sub in
            sub.removeFromSuperview()
        }
        
        self.img.image = AppManager.shared.imageSort(sortModel: self.sortModel)
        
        if isShowButtonSelect {
            self.img.image = img.image?.withRenderingMode(.alwaysTemplate)
            self.img.tintColor = Asset.disableSort.color
        }
        
        self.headerView.addSubview(img)
        self.img.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.img.leftAnchor.constraint(equalTo: self.headerView.leftAnchor, constant: 20),
            self.img.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor, constant: 0)
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
        
        bt.rx.tap.bind { [weak self] _ in
            guard let wSelf = self else { return }
            guard !wSelf.isShowButtonSelect else {
                return
            }
            switch wSelf.sortModel.sortName {
            case .manual:
                if (wSelf.sortModel.isActiveManual ?? false) {
                    let sort: SortModel = SortModel(sortName: wSelf.sortModel.sortName, asc: wSelf.sortModel.asc, isActiveManual: false)
                    wSelf.saveIndex.onNext((sort, wSelf.documents))
                } else {
                    wSelf.moveToSort.onNext(())
                    GATracking.tap(.tapCloudDraftSortMenu)
                }
            case .created_at, .free, .title, .updated_at:
                wSelf.moveToSort.onNext(())
                GATracking.tap(.tapCloudDraftSortMenu)
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
        guard sourceIndexPath != destinationIndexPath else {
            return
        }
        
        let place = self.documents[sourceIndexPath.row]
        self.documents.remove(at: sourceIndexPath.row)
        self.documents.insert(place, at: destinationIndexPath.row)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.totalSelectDrafts >= MultiSelectionInput.Constant.limitSelection {
            tableView.deselectRow(at: indexPath, animated: true)
            self.eventSelectDraftOver.onNext(())
        } else {
            selectAtIndexPath.onNext(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        deselectAtIndexPath.onNext(indexPath)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deletionAction = UIContextualAction(style: .normal, title: nil) { [unowned self] (ac, view, success) in
            self.deleteAtIndexPath.onNext(indexPath)
            success(true)
        }
        
        deletionAction.image = deleteActionTitleImage
        deletionAction.backgroundColor = Asset.deletionAction.color
        
        let movementAction = UIContextualAction(style: .normal, title: nil) { [unowned self] (ac, view, success) in
            self.moveToFolderAtIndexPath.onNext(indexPath)
            success(true)
        }
        
        movementAction.image = moveActionTitleImage
        movementAction.backgroundColor = Asset.pushBackAction.color
        
        let swipeAction = UISwipeActionsConfiguration(actions: [deletionAction, movementAction])
        swipeAction.performsFirstActionWithFullSwipe = false
        
        return swipeAction
    }
}
