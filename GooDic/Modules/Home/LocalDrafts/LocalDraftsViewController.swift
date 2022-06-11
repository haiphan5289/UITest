//
//  LocalDraftsViewController.swift
//  GooDic
//
//  Created by ttvu on 12/16/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

class LocalDraftsViewController: GooTableViewController, MultiSelectionViewProtocol, ViewBindableProtocol, CloudScreenViewProtocol {
    
    struct Constant {
        static let heightHeader: CGFloat = 51
        static let distanceOffsetToHideHeaderView: CGFloat = 20
    }
    
    // MARK: - UI
    private lazy var emptyView: EmptyView = {
        return EmptyView(frame: CGRect(origin: .zero, size: EmptyView.minSize))
    }()
    
    var listFolderCloud: PublishSubject<[Folder]> = PublishSubject.init()
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
    private var disposeBag = DisposeBag()
    var viewModel: LocalDraftsViewModel!
    private var selectAtIndexPath = PublishSubject<IndexPath>()
    private var deselectAtIndexPath = PublishSubject<IndexPath>()
    private var deleteAtIndexPath = PublishSubject<IndexPath>()
    private var moveToFolderAtIndexPath = PublishSubject<IndexPath>()
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
    let eventSelectDraftOver: PublishSubject<Void> = PublishSubject.init()
    var totalSelectDrafts: Int = 0
    
    /// CloudScreenViewProtocol
    let hasChangedTitle = PublishSubject<String>()
    let state = BehaviorSubject<CloudScreenState>(value: .hasData) // faked data
    let hideButtonEventTrigger: PublishSubject<Bool> = PublishSubject.init()
    
    private var isReload: Bool = false

    private let moveToSort: PublishSubject<Void> = PublishSubject.init()
    private var sortModel: SortModel = SortModel.valueDefaultDraft
    private let saveIndex: PublishSubject<SortModel> = PublishSubject.init()
    private let headerView: UIView = UIView(frame: .zero)
    
    private var updateFolder: PublishSubject<(NSFetchedResultsChangeType, IndexPath?)> = PublishSubject.init()
    private var isManual: Bool = false
    private var isShowButtonSelect: Bool = false
    private let img: UIImageView = UIImageView(frame: .zero)
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        bindUI()
        tracking()
        self.setupRX()
    }
    
    deinit {
        print("===== Local Draft")
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
    private func loadSaveData() {
        viewModel.dataSource.setResultsControllerDelegate(frcDelegate: self)
        
        tableView.dataSource = self
        
        tableView.reloadData()
    }
    
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
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        setEditing(false, animated: false)
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
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                emptyView.heightAnchor.constraint(equalToConstant: 400),
                emptyView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                emptyView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
            tableView.layoutIfNeeded()
            self.emptyView.delegate = self
        }
    }
    
    private func bindUI() {
        editMode
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] value in
                guard let wSelf = self else { return }
                
                if wSelf.isEditing == false && wSelf.tableView.isEditing {
                    // In case you swipe only one row, the table view will be in edit mode, but the view controller is still in normal mode. It makes the table view can't go to edit mode directly. So I have to turn it to normal mode before
                    wSelf.tableView.setEditing(false, animated: false)

                    if let indexPathsForVisibleRows = wSelf.tableView.indexPathsForVisibleRows {
                        wSelf.tableView.reloadRows(at: indexPathsForVisibleRows, with: .none)
                    }
                }
                wSelf.setEditing(value, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.didUpdateCloudFolder)
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                // In case users change the folder's name, all related draft belong to it have to update data
                // Just reload visible rows. The other will be reloaded when scrolling
                if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                    self.tableView.reloadRows(at: indexPathsForVisibleRows, with: .none)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        loadSaveData()
        
        let updateUITrigger = Driver.merge(tableView.endUpdatesEvent.asDriver(),
                                           tableView.reloadDataEvent.asDriver().skip(1))
        
        let checkedNewUserTrigger = AppManager.shared.checkedNewUser
            .filter({ $0 })
            .asDriverOnErrorJustComplete()
        
        let saveWhenBackWithManual = self.rx.viewWillDisappear
            .filter { $0 }
            .filter({ [weak self] _ -> Bool in
                guard let wSelf = self else { return false }
                return wSelf.sortModel.sortName == .manual
            })
            .filter { $0 }
            .map({ [weak self] _ -> Bool in
                guard let wSelf = self else { return false }
                return wSelf.tableView.isEditing
            })
            .filter { $0 }
            .map { [weak self] _ -> SortModel in
                guard let wSelf = self else { return  SortModel.valueDefaultDraft }
                return wSelf.sortModel
            }
        
        let saveEvent = Observable.merge(self.saveIndex.asObservable(), saveWhenBackWithManual)
        
        let input = LocalDraftsViewModel.Input(
            loadDataTrigger: Driver.just(()),
            updateUITrigger: updateUITrigger,
            viewDidAppearTrigger: self.rx.viewDidAppear.asDriver().mapToVoid(),
            viewDidLayoutSubviewsTrigger: self.rx.viewDidLayoutSubviews.asDriver().mapToVoid(),
            selectDraftTrigger: selectAtIndexPath.asDriverOnErrorJustComplete(),
            deselectDraftTrigger: deselectAtIndexPath.asDriverOnErrorJustComplete(),
            selectOrDeselectAllDraftsTrigger: selectOrDeselectAllItemsTrigger.asDriverOnErrorJustComplete(),
            moveDraftToFolderTrigger: moveToFolderAtIndexPath.asDriverOnErrorJustComplete(),
            binDraftTrigger: deleteAtIndexPath.asDriverOnErrorJustComplete(),
            moveSelectedDraftsTrigger: moveItemsTrigger.asDriverOnErrorJustComplete(),
            binSelectedDraftsTrigger: binItemsTrigger.asDriverOnErrorJustComplete(),
            editingModeTrigger: editMode.asDriverOnErrorJustComplete(),
            touchSwipeDocumentTooltipTrigger: interactWithSwipeDocumentTutorial.asDriverOnErrorJustComplete(),
            checkedNewUserTrigger: checkedNewUserTrigger,
            moveToSort: self.moveToSort.asDriverOnErrorJustComplete(),
            updateFolder: self.updateFolder.asDriverOnErrorJustComplete(),
            saveIndex: saveEvent.asDriverOnErrorJustComplete(),
            viewWillDisAppear: self.rx.viewWillDisappear.mapToVoid().asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.title
            .drive(onNext: { [weak self] (title) in
                guard let self = self else { return }
                let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 18)]
                self.navigationBarTitle.attributedText = NSAttributedString(string: title, attributes: atts)
            })
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
            .drive(onNext: { [weak self] (indexPath) in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        let hasRealData = output.realDataCount
            .map({ $0 > 0 })
        
        Driver
            .merge(
                output.movedDraftsToFolder,
                output.binDrafts)
            .withLatestFrom(hasRealData)
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
        
        output.hasData
            .drive(onNext: { [weak self] (hasData) in
                guard let self = self else { return  }
                
                self.showEmptyView(!hasData)
            })
            .disposed(by: self.disposeBag)
        
        output.realDataCount
            .drive(onNext: { [weak self] value in
                self?.itemCount.onNext(value)
            })
            .disposed(by: self.disposeBag)
        
        
        hasRealData
            .drive(onNext: { [weak self] hasData in
                guard let self = self else { return }
                
                self.showEmptyView(!hasData)
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
        
        Driver
            .combineLatest(output.emptyViewModel, output.hasData)
            .drive(onNext: { [weak self] emptyVM, hasData in
                self?.setupEmptyView(with: emptyVM)
                self?.showEmptyView(!hasData)
            })
            .disposed(by: self.disposeBag)
        
        Observable.combineLatest(output.folderStream.asObservable(), output.updateSort.asObservable()).take(1).bind {  [weak self] folderId, sort in
            switch folderId {
            case .none:
                GATracking.sendUserProperties(property: .draftSortOrder(sort))
                break
            case .local:
                GATracking.sendUserProperties(property: .draftSortOrderFolder(sort))
                break
            case .cloud(_):
                break
            }
        }.disposed(by: self.disposeBag)

        
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

        output.autoHideToolTips
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loading
            .drive(onNext: {[weak self] show in
                if show {
                    GooLoadingViewController.shared.show()
                } else {
                    GooLoadingViewController.shared.hide()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.moveToSort.drive().disposed(by: self.disposeBag)
        
        output.updateSort.drive { [weak self] sort in
            guard let wSelf = self, let isActiveManual = sort.isActiveManual else { return }
            wSelf.sortModel = sort
            wSelf.tableView.reloadData()
            switch sort.sortName {
            case .manual:
                wSelf.isManual = isActiveManual
                wSelf.tableView.setEditing(isActiveManual, animated: true)
                wSelf.tableView.allowsMultipleSelectionDuringEditing = !isActiveManual
            case .created_at, .free, .title, .updated_at:
                wSelf.isManual = false
                wSelf.tableView.setEditing(false, animated: true)
                wSelf.tableView.allowsMultipleSelectionDuringEditing = true
            }
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(output.folderStream.asObservable(), output.updateSort.asObservable()).take(1).bind { folderId, sort in
            switch folderId {
            case .none:
                GATracking.sendUserProperties(property: .draftSortOrder(sort))
            case .local:
                GATracking.sendUserProperties(property: .draftSortOrderFolder(sort))
            case .cloud(_): break
                
            }
        }.disposed(by: self.disposeBag)

        
        output.updateFolderCoreData.drive().disposed(by: self.disposeBag)
        
        output.updateFolder.drive().disposed(by: self.disposeBag)
        
        output.hideButton.drive { [weak self] ishide in
            guard let wSelf = self else { return }
            wSelf.hideButtonEventTrigger.onNext(ishide)
        }.disposed(by: self.disposeBag)
        
        //re-perform fetch coredata the updating latest999
        Observable.combineLatest(self.viewModel.dataSource.reloadData, output.saveTypeDraft.startWith(.required).asObservable())
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .bind { [weak self] (_, type) in
                guard let wSelf = self, type != .auto else { return }
                print("==== reload drafts \(type)")
                wSelf.viewModel.dataSource.sortFolder(sort: wSelf.sortModel, isSave: false)
                wSelf.tableView.reloadData()
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
}

extension LocalDraftsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DocumentTVC.reuseIdentifier, for: indexPath)
        if self.viewModel.dataSource.hasIndex(indexPath: indexPath) {
            configureCell(cell, at: indexPath)
        }
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let doc = viewModel.dataSource.data(at: indexPath)
        let documentCell = cell as! DocumentTVC
        let folderName = doc.getFolderName()
//        if self.isManual {
//            documentCell.setupViewSort()
//        } else {
//            documentCell.removeReorderView()
//        }
        documentCell.isManual = self.isManual
        documentCell.bind(title: doc.title,
                          content: doc.content,
                          date: doc.updatedAt.toString,
                          folderName: folderName)
    }
}

extension LocalDraftsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.dataSource.numberOfRows(in: section) > 0 {
            return Constant.heightHeader
        }
        return 0
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
                if wSelf.sortModel.isActiveManual ?? false {
                    let sort: SortModel = SortModel(sortName: wSelf.sortModel.sortName, asc: wSelf.sortModel.asc, isActiveManual: false)
                    wSelf.saveIndex.onNext(sort)
                } else {
                    wSelf.moveToSort.onNext(())
                    GATracking.tap(.tapDraftSortMenu)
                }
            case .created_at, .free, .title, .updated_at:
                wSelf.moveToSort.onNext(())
                GATracking.tap(.tapDraftSortMenu)
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

        let place = self.viewModel.dataSource.drafts[sourceIndexPath.row]
        self.viewModel.dataSource.drafts.remove(at: sourceIndexPath.row)
        self.viewModel.dataSource.drafts.insert(place, at: destinationIndexPath.row)
        tableView.reloadData()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        
        interactWithSwipeDocumentTutorial.onNext(())
        
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

extension LocalDraftsViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.isReload = false
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        var indexPath: IndexPath? = indexPath
        var newIndexPath: IndexPath? = newIndexPath
        self.viewModel.dataSource.getActionFetch(at: &indexPath, for: type, newIndexPath: &newIndexPath, sort: self.sortModel)
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
                self.isReload = true
                self.updateFolder.onNext((type, indexPath))
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.isReload = false
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell, at: indexPath)
                    self.isReload = true
                    self.updateFolder.onNext((type, indexPath))
                }
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                self.isReload = true
                self.updateFolder.onNext((type, newIndexPath))
            }
        @unknown default:
            fatalError()
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        guard self.isReload, tableView.hasRowAtIndexPath(indexPath: IndexPath(row: 0, section: 0)) else {
            return
        }

        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
}
extension LocalDraftsViewController: EmptyViewDelegate {
    func saveIndex(sortModel: SortModel) {
        self.saveIndex.onNext(sortModel)
    }
    
    func moveToSortEmpty() {
        self.moveToSort.onNext(())
    }
}
