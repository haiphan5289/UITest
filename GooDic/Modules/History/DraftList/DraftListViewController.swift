//
//  DraftListViewController.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData
import FirebaseAnalytics
import FirebaseInAppMessaging

class DraftListViewController: BaseViewController {
    
    // MARK: - UI
    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var openDraftButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var tutorialAddDocumentPopup: UIImageView!
    var tutorialSwipeDocumentPopup: UIImageView!
    var headerView = UIView()
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: DraftListViewModel!
    var selectAtIndexPath = PublishSubject<IndexPath>()
    var deleteAtIndexPath = PublishSubject<IndexPath>()
    var moveToFolderAtIndexPath = PublishSubject<IndexPath>()
    var interactWithAddNewDocumentTutorial = PublishSubject<Void>()
    var interactWithSwipeDocumentTutorial = PublishSubject<Void>()
    var checkEmptyDocTrigger = PublishSubject<Void>()
    private lazy var noItemView: NoItemView = NoItemView(image: Asset.imgEmpty01.image,
                                                         parentView: self.tableView,
                                                         lbMessage: nil)
    private var isReload: Bool = false
    
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
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAccessibility()
        bindUI()
        bindViewModel()
        loadSaveData()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // allow (enable) render in-app messaging
        InAppMessaging.inAppMessaging().messageDisplaySuppressed = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // send event to open in-app messaging if needed
        InAppMessaging.inAppMessaging().triggerEvent(GlobalConstant.iamOpenHomeViewTrigger)
        
        // emit check empty documents to delete them
        checkEmptyDocTrigger.onNext(())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // disallow (disable) render in-app messaging
        InAppMessaging.inAppMessaging().messageDisplaySuppressed = true
        
        tableView.isEditing = false
    }
    private func loadSaveData() {
        viewModel.frc.delegate = self
        
        do {
            try viewModel.frc.performFetch()
            tableView.reloadData()
        } catch {
            print("Fetch failed")
        }
    }
    
    private func setupUI() {
        // handle tabBar to hide or show, we check a view controller which will be showed
        if self.navigationController?.delegate == nil {
            self.navigationController?.delegate = self
        }
        
        navigationController?.navigationBar.tintColor = Asset.textPrimary.color
        tableView.tableHeaderView = headerView
        tableView.rowHeight = DocumentTVC.Constant.cellHeight
        tableView.estimatedRowHeight = DocumentTVC.Constant.cellHeight
        
        let cellName = String(describing: DocumentTVC.self)
        let nib = UINib(nibName: cellName, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: DocumentTVC.reuseIdentifier)
        
        tableView.hideEmptyCells()
        
        // setup tutorial popup
        self.tutorialAddDocumentPopup = UIImageView(image: Asset.imgTutoEdit.image)
        self.tutorialAddDocumentPopup.addTapGesture { [weak self] (gesture) in
            self?.interactWithAddNewDocumentTutorial.onNext(())
        }
        
        self.tutorialSwipeDocumentPopup = UIImageView(image: Asset.imgTutoDraft.image)
        self.tutorialSwipeDocumentPopup.addTapGesture { [weak self] (gesture) in
            self?.interactWithSwipeDocumentTutorial.onNext(())
        }
    }
    
    private func setupEmptyView(with model: AlertViewModel) {
//        // setup Empty View
//        let alertView = AlertViewController.create()
//        alertView.viewModel = model
//
//        self.addChild(alertView)
//        self.view.insertSubview(alertView.view, at: 0)
    }
    
    private func setupAccessibility() {
        self.openDraftButton.accessibilityLabel = "creation"
    }
    
    private func bindUI() {
        // Tracking Tap events
        let tapCreateDraft = openDraftButton.rx.tap
            .map({ GATracking.Tap.tapCreateDraft })
            
        let tapRemoveDraft = trashButton.rx.tap
            .map({ GATracking.Tap.tapRemoveDraft })
        
        let moveToAction = moveToFolderAtIndexPath
            .map({ _ in GATracking.Tap.tapMoveToFolder })
            
        Observable.merge(tapCreateDraft, tapRemoveDraft, moveToAction)
            .subscribe(onNext: GATracking.tap)
            .disposed(by: self.disposeBag)
    }
    
    private func bindViewModel() {
        let updateUITrigger = Driver.merge(tableView.endUpdatesEvent.asDriver(),
                                           tableView.reloadDataEvent.asDriver().skip(1))
        
        let input = DraftListViewModel.Input(
            loadDataTrigger: Driver.just(()),
            updateUITrigger: updateUITrigger,
            checkEmptyDocTrigger: checkEmptyDocTrigger.asDriverOnErrorJustComplete(),
            selectDocumentTrigger: selectAtIndexPath.asDriverOnErrorJustComplete(),
            moveDocumentToFolderTrigger: moveToFolderAtIndexPath.asDriverOnErrorJustComplete(),
            binDocumentTrigger: deleteAtIndexPath.asDriverOnErrorJustComplete(),
            openCreationTrigger: openDraftButton.rx.tap.asDriver(),
            openTrashTrigger: trashButton.rx.tap.asDriver(),
            touchAddNewDocumentTutorialTrigger: interactWithAddNewDocumentTutorial.asDriverOnErrorJustComplete(),
            touchSwipeDocumentTutorialTrigger: interactWithSwipeDocumentTutorial.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.title
            .drive(onNext: { [weak self] (title) in
                guard let self = self else { return }
                let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 18)]
                self.navigationBarTitle.attributedText = NSAttributedString(string: title, attributes: atts)
            })
            .disposed(by: self.disposeBag)
        
        output.openCreation
            .drive()
            .disposed(by: self.disposeBag)
        output.selectedDocument
            .drive()
            .disposed(by: self.disposeBag)
        
        output.movedDocumentToFolder
            .drive()
            .disposed(by: self.disposeBag)
        
        output.binDocument
            .drive()
            .disposed(by: self.disposeBag)
        
        output.openTrash
            .drive()
            .disposed(by: self.disposeBag)
        
        output.hasData
            .map({ !$0 })
            .drive(onNext: { [weak self] (isHidden) in
                guard let self = self else { return  }
                UIView.animate(withDuration: 0.3) {
                    isHidden ? self.noItemView.addView() : self.noItemView.removeView()
                }
            })
            .disposed(by: self.disposeBag)
        
        output.showAddDocumentTutorial
            .drive(onNext: { [weak self] (show) in
                guard let self = self else { return }
                
                if show {
                    var config = UIView.AnimConfig()
                    config.popupAnchorPoint = UIView.AnchorPoint.anchor(
                        CGPoint(x: self.tutorialAddDocumentPopup.frame.width - self.openDraftButton.frame.width * 0.5,
                                y: self.tutorialAddDocumentPopup.frame.height + 10))
                    config.targetAnchorPoint = UIView.AnchorPoint.centerTop
                    
                    self.view.show(popup: self.tutorialAddDocumentPopup, targetRect: self.openDraftButton.frame, config: config)
                } else {
                    self.view.dismiss(popup: self.tutorialAddDocumentPopup)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.showSwipeDocumentTutorial
            .drive(onNext: { [weak self] show in
                guard let self = self else { return }
                
                if show {
                    if let cell = self.tableView.visibleCells.first {
                        var config = UIView.AnimConfig()
                        config.popupAnchorPoint = UIView.AnchorPoint.anchor(CGPoint(x: self.tutorialSwipeDocumentPopup.bounds.width * 0.5, y: 0))
                        config.targetAnchorPoint = UIView.AnchorPoint.anchor(CGPoint(x: cell.frame.maxX - self.tutorialSwipeDocumentPopup.bounds.width * 0.5 - 10, y: cell.frame.maxY))
                        
                        self.tableView.show(popup: self.tutorialSwipeDocumentPopup, targetRect: cell.frame, config: config, controlView: self.headerView)
                    }
                } else {
                    self.tableView.dismiss(popup: self.tutorialSwipeDocumentPopup, verticalAnim: -5)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.emptyViewModel
            .drive(onNext: { [weak self] emptyVM in
                self?.setupEmptyView(with: emptyVM)
            })
            .disposed(by: self.disposeBag)
    }
}

extension DraftListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.frc.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = viewModel.frc.sections![section]
        return sectionInfo.numberOfObjects
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
        let doc = viewModel.frc.object(at: indexPath).document
        let documentCell = cell as! DocumentTVC
        documentCell.bind(title: doc.title, date: doc.updatedAt.toString, content: doc.content)
    }
}

extension DraftListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectAtIndexPath.onNext(indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
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

extension DraftListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.isReload = false
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
                self.isReload = true
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
                }
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                self.isReload = true
            }
        @unknown default:
            fatalError()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        
        guard self.isReload else {
            return
        }
        
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
}

extension DraftListViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // only show tabBar if viewController is DraftListViewController
        self.tabBarController?.tabBar.isHidden = !(viewController is DraftListViewController)
    }
}
