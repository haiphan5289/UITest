//
//  TrashViewController.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData
import FirebaseAnalytics

class TrashViewController: BaseViewController, ViewBindableProtocol {
    
    // MARK: - UI
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var pushBackBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarConstraintBottom: NSLayoutConstraint!
    
    lazy var selectOrDeselectAllBarButtonItem: UIBarButtonItem = {
        createBarButtonItem(with: L10n.Draft.BarButtonItem.selectAll)
    }()
    
    lazy var cancelBarButtonItem: UIBarButtonItem = {
        createBarButtonItem(with: L10n.Draft.BarButtonItem.cancel)
    }()
    
    // create this image to custom action's title
    lazy var pushBackActionTitleImage: UIImage? = {
        UIImage.createActionTitleImage(name: L10n.Trash.Action.pushBack)
    }()
    
    private lazy var emptyView: EmptyView = {
        let view = EmptyView(frame: CGRect(origin: .zero, size: EmptyView.minSize))
        view.bind(type: .noDraftInTrash)
        return view
    }()
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: TrashViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var deselectAtIndexPath = PublishSubject<IndexPath>()
    var pushBackAtIndexPath = PublishSubject<IndexPath>()
    var backToNormalModelTrigger = PublishSubject<Void>()
    var eventSelectDraftOver: PublishSubject<Void> = PublishSubject.init()
    var totalSelectDrafts: Int = 0
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // the extended actions caches its indexPath as soon as displaying.
        // So if the data of table view is added or removed, it will emit with a wrong indexPath
        // to prevent, we have to hide it before the view has disappeared off the screen
        if self.isEditing == false {
            self.tableView.isEditing = false
        }
    }
    
    // MARK: - Funcs
    private func loadSaveData() {
        viewModel.setResultsControllerDelegate(frcDelegate: self)
        
        tableView.dataSource = self
        
        tableView.reloadData()
    }
    
    private func setupUI() {
        tableView.rowHeight = DocumentTVC.Constant.cellHeight
        tableView.estimatedRowHeight = DocumentTVC.Constant.cellHeight
        
        let cellName = String(describing: DocumentTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: DocumentTVC.reuseIdentifier)
        tableView.hideEmptyCells()
        tableView.separatorColor = Asset.cellSeparator.color
        
        // setup Empty View
        self.view.insertSubview(emptyView, at: 0)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            emptyView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            emptyView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
            emptyView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        tableView.delegate = self
        
        setEditing(false, animated: false)
        
        self.hidesBottomBarWhenPushed = true
    }
    
    private func bindUI() {
        Driver
            .merge(
                editButtonItem.rx.tap.asDriver(),
                cancelBarButtonItem.rx.tap.asDriver())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                if self.isEditing == false && self.tableView.isEditing {
                    // In case you swipe only one row, the table view will be in edit mode, but the view controller is still in normal mode. It makes the table view can't go to edit mode directly. So I have to turn it to normal mode before
                    self.tableView.setEditing(false, animated: false)
                    
                    if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                        self.tableView.reloadRows(at: indexPathsForVisibleRows, with: .none)
                    }
                }
                
                self.setEditing(!self.isEditing, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        loadSaveData()
        
        let updateUITrigger = Driver.merge(tableView.endUpdatesEvent.asDriver(),
                                           tableView.reloadDataEvent.asDriver().skip(1))
        
        let editingModeTrigger = Driver
            .merge(
                editButtonItem.rx.tap.asDriver(),
                cancelBarButtonItem.rx.tap.asDriver(),
                backToNormalModelTrigger.asDriverOnErrorJustComplete())
            .map({ self.tableView.isEditing })
            .startWith(false)
        
        let input = TrashViewModel.Input(
            loadTrigger: Driver.just(()),
            updateUITrigger: updateUITrigger,
            selectDraftTrigger: selectAtIndexPath.asDriverOnErrorJustComplete(),
            deselectDraftTrigger: deselectAtIndexPath.asDriverOnErrorJustComplete(),
            pushBackDraftTrigger: pushBackAtIndexPath.asDriverOnErrorJustComplete(),
            editingModeTrigger: editingModeTrigger,
            selectOrDeselectAllDraftsTrigger: selectOrDeselectAllBarButtonItem.rx.tap.asDriver(),
            deleteSelectedDraftsTrigger: deleteBarButtonItem.rx.tap.asDriver(),
            pushBackSelectedDraftsTrigger: pushBackBarButtonItem.rx.tap.asDriver(),
            eventSelectDraftOver: eventSelectDraftOver.asDriverOnErrorJustComplete()
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
            
        
//        output.selectOrDeselectAllRows
//            .drive(onNext: { [weak self] (seletedType) in
//                guard let self = self else { return }
//                switch seletedType {
//                case let .selectAll(indexPaths):
//                    indexPaths.forEach {
//                        self.tableView.selectRow(at: $0, animated: true, scrollPosition: .none)
//                    }
//
//                case let .deselectAll(indexPaths):
//                    indexPaths.forEach {
//                        self.tableView.deselectRow(at: $0, animated: true)
//                    }
//                }
//            })
//            .disposed(by: self.disposeBag)
        
        output.openedDraftInReference
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        
        Driver
            .merge(
                output.deletedDrafts,
                output.pushBackDrafts)
            .withLatestFrom(output.hasData)
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
            .map({ !$0 })
            .drive(onNext: { [weak self] (isHidden) in
                guard let self = self else { return  }
                UIView.animate(withDuration: 0.3) {
                    self.tableView.alpha = isHidden ? 0 : 1
                }
            })
            .disposed(by: self.disposeBag)
        
        output.hasData
            .drive(onNext: { [weak self] (hasData) in
                guard let self = self else { return  }
                
                self.navigationItem.setRightBarButton(hasData ? self.editButtonItem : nil, animated: false)
            })
            .disposed(by: self.disposeBag)
        
        output.hasSelectedItems
            .drive(self.deleteBarButtonItem.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
        output.hasSelectedItems
            .drive(self.pushBackBarButtonItem.rx.isEnabled)
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
        
        output.selectedDrafts
            .map { (list) -> String in
                let text = (list.count > 0) ? L10n.Draft.BarButtonItem.deselectAll :  L10n.Draft.BarButtonItem.selectAll
                return text
            }
            .drive(self.selectOrDeselectAllBarButtonItem.rx.title)
            .disposed(by: self.disposeBag)
        
        output.selectedDrafts.drive { [weak self] list in
            guard let wSelf = self else { return }
            wSelf.totalSelectDrafts = list.count
        }.disposed(by: disposeBag)
        
        output.eventSelectDraftOver.drive().disposed(by: disposeBag)
        output.showPremium.drive().disposed(by: disposeBag)

    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)

        let animationDuration: TimeInterval = 0.2
        if editing {
            navigationItem.setRightBarButton(cancelBarButtonItem, animated: true)
            navigationItem.setLeftBarButton(selectOrDeselectAllBarButtonItem, animated: true)

            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .linear) { [weak self] in
                guard let self = self else { return }
                
                self.toolbarConstraintBottom.constant = 0
                self.toolbar.alpha = 1
                self.view.layoutIfNeeded()
            }
            
            animator.startAnimation()
            
            NotificationCenter.default.post(name: .hideTabBar, object: nil)
        } else {
            editButtonItem.tintColor = Asset.blueHighlight.color
            navigationItem.setRightBarButton(editButtonItem, animated: true)
            navigationItem.setLeftBarButton(nil, animated: true)
            
            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .linear) { [weak self] in
                guard let self = self else { return }
                
                let safeAreaBottom = UIWindow.key?.safeAreaInsets.bottom ?? 0
                let height = self.toolbar.bounds.height + safeAreaBottom
                self.toolbarConstraintBottom.constant = -height
                self.toolbar.alpha = 0
                self.view.layoutIfNeeded()
            }
            
            animator.startAnimation()
            
            NotificationCenter.default.post(name: .showTabBar, object: nil)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

// MARK: - UITableViewDataSource
extension TrashViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DocumentTVC.reuseIdentifier, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let doc = viewModel.data(at: indexPath)
        let documentCell = cell as! DocumentTVC
        documentCell.bind(title: doc.title, content: doc.content, date: doc.updatedAt.toString)
    }
}

// MARK: - UITableViewDelegate
extension TrashViewController: UITableViewDelegate {
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
        
        let pushBackAction = UIContextualAction(style: .normal, title: nil) { [unowned self] (ac, view, success) in
            self.pushBackAtIndexPath.onNext(indexPath)
            success(true)
        }
        
        pushBackAction.image = pushBackActionTitleImage
        pushBackAction.backgroundColor = Asset.pushBackAction.color
        
        let swipeAction = UISwipeActionsConfiguration(actions: [pushBackAction])
        swipeAction.performsFirstActionWithFullSwipe = false
        
        return swipeAction
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrashViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
}
