//
//  CloudDraftsViewController.swift
//  GooDic
//
//  Created by ttvu on 12/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics
import FirebaseInAppMessaging

class CloudDraftsViewController: GooCloudTableViewController, ViewBindableProtocol {
    
    // MARK: - UI
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
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindUI()
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
        
        tableView.delegate = self
        setEditing(false, animated: false)
    }
    
    private func setupEmptyView(with model: AlertViewModel) {
        // setup Empty View
        let alertView = AlertViewController.create()
        alertView.viewModel = model
        
        self.addChild(alertView)
        self.view.insertSubview(alertView.view, at: 0)
    }
    
    private func bindUI() {
//        Driver
//            .merge(
//                editButtonItem.rx.tap.asDriver(),
//                cancelBarButtonItem.rx.tap.asDriver())
//            .drive(onNext: { [weak self] _ in
//                guard let self = self else { return }
//
//                if self.isEditing == false && self.tableView.isEditing {
//                    // In case you swipe only one row, the table view will be in edit mode, but the view controller is still in normal mode. It makes the table view can't go to edit mode directly. So I have to turn it to normal mode before
//                    self.tableView.setEditing(false, animated: false)
//
//                    if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
//                        self.tableView.reloadRows(at: indexPathsForVisibleRows, with: .none)
//                    }
//                }
//
//                self.setEditing(!self.isEditing, animated: true)
//            })
//            .disposed(by: self.disposeBag)
//
//        NotificationCenter.default.rx
//            .notification(.didChangeFolderName)
//            .asDriverOnErrorJustComplete()
//            .drive(onNext: { [weak self] _ in
//                guard let self = self else { return }
//
//                // In case users change the folder's name, all related draft belong to it have to update data
//                // Just reload visible rows. The other will be reloaded when scrolling
//                if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
//                    self.tableView.reloadRows(at: indexPathsForVisibleRows, with: .none)
//                }
//            })
//            .disposed(by: self.disposeBag)
//
//        // Tracking Tap events
//        let tapCreateDraft = creationButton.rx.tap
//            .map({ GATracking.Tap.tapCreateDraft })
//
//        let removeAction = deleteAtIndexPath
//            .map({ _ in GATracking.Tap.tapRemoveDraft })
//
//        let moveToAction = moveToFolderAtIndexPath
//            .map({ _ in GATracking.Tap.tapMoveToFolder })
//
//        Observable.merge(tapCreateDraft, removeAction, moveToAction)
//            .subscribe(onNext: GATracking.tap)
//            .disposed(by: self.disposeBag)
        tableView.rx
            .setDelegate(self)
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        let loadMoreTrigger = getLoadMoreTrigger()
        let reloadTrigger = getReloadTrigger()
        
//        let updateUITrigger = Driver.merge(tableView.endUpdatesEvent.asDriver(),
//                                           tableView.reloadDataEvent.asDriver().skip(1))
//
//        let editingModeTrigger = Driver
//            .merge(
//                editButtonItem.rx.tap.asDriver(),
//                cancelBarButtonItem.rx.tap.asDriver(),
//                backToNormalModelTrigger.asDriverOnErrorJustComplete())
//            .map({ self.tableView.isEditing })
//            .startWith(false)
        let input = CloudDraftsViewModel.Input(
            loadDataTrigger: self.rx.viewDidAppear.take(1).asDriverOnErrorJustComplete().mapToVoid(),
            reloadTrigger: reloadTrigger,
            loadMoreTrigger: loadMoreTrigger,
            selectDraftTrigger: selectAtIndexPath.asDriverOnErrorJustComplete(),
            deselectDraftTrigger: deselectAtIndexPath.asDriverOnErrorJustComplete(),
            moveDraftToFolderTrigger: moveToFolderAtIndexPath.asDriverOnErrorJustComplete(),
            binDraftTrigger: deleteAtIndexPath.asDriverOnErrorJustComplete())
        
//        let input = DraftListViewModel.Input(
//            loadDataTrigger: Driver.just(()),
//            updateUITrigger: updateUITrigger,
//            viewDidAppearTrigger: viewDidAppearTrigger.asDriverOnErrorJustComplete(),
//            viewDidLayoutSubviewsTrigger: viewDidLayoutSubviewsTrigger.asDriverOnErrorJustComplete(),
//            selectDraftTrigger: selectAtIndexPath.asDriverOnErrorJustComplete(),
//            deselectDraftTrigger: deselectAtIndexPath.asDriverOnErrorJustComplete(),
//            selectOrDeselectAllDraftsTrigger: selectOrDeselectAllBarButtonItem.rx.tap.asDriver(),
//            moveDraftToFolderTrigger: moveToFolderAtIndexPath.asDriverOnErrorJustComplete(),
//            binDraftTrigger: deleteAtIndexPath.asDriverOnErrorJustComplete(),
//            moveSelectedDraftsTrigger: moveToBarButtonItem.rx.tap.asDriver(),
//            binSelectedDraftsTrigger: deleteBarButtonItem.rx.tap.asDriver(),
//            openCreationTrigger: creationButton.rx.tap.asDriver(),
//            editingModeTrigger: editingModeTrigger,
//            touchAddNewDocumentTooltipTrigger: interactWithAddNewDocumentTutorial.asDriverOnErrorJustComplete(),
//            touchSwipeDocumentTooltipTrigger: interactWithSwipeDocumentTutorial.asDriverOnErrorJustComplete(),
//            touchEditModeTooltipTrigger: interactWithEditModeTutorial.asDriverOnErrorJustComplete(),
//            checkedNewUserTrigger: checkedNewUserTrigger
//        )
        
        let output = viewModel.transform(input)
        
        
        output.drafts
            .withLatestFrom(output.folder, resultSelector: { (list, folder) -> [CloudDocument] in
                return list.map({ CloudDocument(id: $0.id,
                                                title: $0.title,
                                                content: $0.content,
                                                updatedAt: $0.updatedAt,
                                                folderId: folder.name)
                })
            })
            .drive(self.tableView.rx.items(cellIdentifier: DocumentTVC.reuseIdentifier, cellType: DocumentTVC.self),
                   curriedArgument: { index, model, cell in
                    cell.bind(title: model.title,
                              content: model.content,
                              date: model.updatedAt.toString,
                              folderName: model.folderId,
                              onCloud: true)
                   })
            .disposed(by: self.disposeBag)
        
        output.error
            .drive()
            .disposed(by: self.disposeBag)
        
        output.isLoading
            .drive(centerActivityIndicator.rx.isAnimating)
            .disposed(by: self.disposeBag)
        
        output.isLoading
            .drive(tableView.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        output.isReloading
            .drive(self.refreshControl.rx.isRefreshing)
            .disposed(by: self.disposeBag)
        
        output.isLoadingMore
            .drive(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                
                self.tableView.tableFooterView = isLoading ? self.footer : nil
            })
            .disposed(by: self.disposeBag)
        
        output.isLoadingMore
            .drive(self.bottomActivityIndicator.rx.isAnimating)
            .disposed(by: self.disposeBag)
        
        output.openedDraft
            .drive()
            .disposed(by: self.disposeBag)
        
//        output.title
//            .debug("title")
//            .drive(onNext: { [weak self] (title) in
//                guard let self = self else { return }
//                let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 18)]
//                self.navigationBarTitle.attributedText = NSAttributedString(string: title, attributes: atts)
//            })
//            .disposed(by: self.disposeBag)
//
//        output.updateSelectedType
//            .map({
//                if case .deselectAll(_) = $0 {
//                    return L10n.Draft.BarButtonItem.deselectAll
//                }
//
//                return L10n.Draft.BarButtonItem.selectAll
//            })
//            .drive(self.selectOrDeselectAllBarButtonItem.rx.title)
//            .disposed(by: self.disposeBag)
//
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
//
//        output.openCreation
//            .drive()
//            .disposed(by: self.disposeBag)
//
//        output.openedDraft
//            .drive(onNext: { [weak self] (indexPath) in
//                self?.tableView.deselectRow(at: indexPath, animated: true)
//            })
//            .disposed(by: self.disposeBag)
//
//        Driver
//            .merge(
//                output.movedDraftsToFolder,
//                output.binDrafts)
//            .withLatestFrom(output.hasRealData)
//            .drive(onNext: { [weak self] (hasData) in
//                guard let self = self else { return }
//                self.setEditing(false, animated: true)
//                self.backToNormalModelTrigger.onNext(())
//
//                self.navigationItem.setRightBarButton(hasData ? self.editButtonItem : nil, animated: false)
//            })
//            .disposed(by: self.disposeBag)
//
//        output.hasData
//            .map({ !$0 })
//            .drive(onNext: { [weak self] (isHidden) in
//                guard let self = self else { return  }
//                UIView.animate(withDuration: 0.3) {
//                    self.tableView.alpha = isHidden ? 0 : 1
//                }
//            })
//            .disposed(by: self.disposeBag)
//
//        output.hasRealData
//            .drive(onNext: { [weak self] hasData in
//                guard let self = self else { return }
//                self.navigationItem.setRightBarButton(hasData ? self.editButtonItem : nil, animated: false)
//            })
//            .disposed(by: self.disposeBag)
//
//        output.showAddDocumentTooltip
//            .drive(onNext: { [weak self] (show) in
//                guard let self = self else { return }
//
//                if show {
//                    var config = UIView.AnimConfig()
//                    config.popupAnchorPoint = UIView.AnchorPoint.anchor(
//                        CGPoint(x: self.tutorialAddDocumentPopup.frame.width - self.creationButton.frame.width * 0.5,
//                                y: self.tutorialAddDocumentPopup.frame.height + 10))
//                    config.targetAnchorPoint = UIView.AnchorPoint.centerTop
//
//                    self.view.show(popup: self.tutorialAddDocumentPopup, targetRect: self.creationButton.frame, config: config, controlView: self.creationButton)
//                } else {
//                    self.view.dismiss(popup: self.tutorialAddDocumentPopup, verticalAnim: -5)
//                }
//            })
//            .disposed(by: self.disposeBag)
//
//        output.showSwipeDocumentTooltip
//            .drive(onNext: { [weak self] show in
//                guard
//                    let self = self,
//                    let cell = self.tableView.visibleCells.first
//                else { return }
//
//                if show {
//                    // reference to XD file
//                    let paddingTop: CGFloat = 4.0
//                    let paddingRight: CGFloat = 14.0
//                    let pointingCornerPaddingRight: CGFloat = 60.0
//
//                    let popupAnchorPoint = CGPoint(x: self.tutorialSwipeDocumentPopup.bounds.width - pointingCornerPaddingRight, y: 0)
//                    let targetAnchorPoint = CGPoint(x: cell.bounds.width - pointingCornerPaddingRight - paddingRight, y: cell.bounds.height + paddingTop)
//
//                    var config = UIView.AnimConfig()
//                    config.popupAnchorPoint = UIView.AnchorPoint.anchor(popupAnchorPoint)
//                    config.targetAnchorPoint = UIView.AnchorPoint.anchor(targetAnchorPoint)
//
//                    self.tableView.show(popup: self.tutorialSwipeDocumentPopup, targetRect: cell.frame, config: config)
//
//                } else {
//                    self.tableView.dismiss(popup: self.tutorialSwipeDocumentPopup, verticalAnim: -5)
//                }
//            })
//            .disposed(by: self.disposeBag)
//
//        Driver
//            .combineLatest(
//                output.showEditModeTooltip,
//                output.hasRealData, resultSelector: { (status: $0, hasData: $1) })
//            .map({ $0.hasData ? $0.status : false })
//            .drive(onNext: { [weak self] show in
//                guard
//                    let self = self,
//                    let buttonView = self.editButtonItem.view
//                else { return }
//
//                if show && self.navigationItem.rightBarButtonItem != nil {
//                    let frameInView = buttonView.convert(buttonView.bounds, to: self.view)
//
//                    // reference to XD file
//                    let paddingTop: CGFloat = 6.0
//                    let pointingCornerPaddingRight: CGFloat = 24.0
//                    let popupAnchorPoint = CGPoint(x: self.tutorialEditModePopup.bounds.width - pointingCornerPaddingRight, y: 0)
//                    let targetAnchorPoint = CGPoint(x: frameInView.midX, y: frameInView.maxY + paddingTop)
//
//                    var config = UIView.AnimConfig()
//                    config.popupAnchorPoint = UIView.AnchorPoint.anchor(popupAnchorPoint)
//                    config.targetAnchorPoint = UIView.AnchorPoint.anchor(targetAnchorPoint)
//
//                    self.view.show(popup: self.tutorialEditModePopup, targetRect: frameInView, config: config)
//                } else {
//                    self.view.dismiss(popup: self.tutorialEditModePopup, verticalAnim: -5)
//                }
//            })
//            .disposed(by: self.disposeBag)
//
//        output.emptyViewModel
//            .drive(onNext: { [weak self] emptyVM in
//                self?.setupEmptyView(with: emptyVM)
//            })
//            .disposed(by: self.disposeBag)
//
//        output.hasSelectedItems
//            .drive(self.deleteBarButtonItem.rx.isEnabled)
//            .disposed(by: self.disposeBag)
//
//        output.hasSelectedItems
//            .drive(self.moveToBarButtonItem.rx.isEnabled)
//            .disposed(by: self.disposeBag)
//
//        output.autoHideToolTips
//            .drive()
//            .disposed(by: self.disposeBag)
    }
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//        self.tableView.setEditing(editing, animated: animated)
//
//        let animationDuration: TimeInterval = 0.2
//        if editing {
//            navigationItem.setRightBarButton(cancelBarButtonItem, animated: true)
//            navigationItem.setLeftBarButton(selectOrDeselectAllBarButtonItem, animated: true)
//
//            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .linear) { [weak self] in
//                guard let self = self else { return }
//
//                self.creationButton.alpha = 0
//                self.toolbar.alpha = 1
//            }
//
//            animator.startAnimation()
//
//            NotificationCenter.default.post(name: .hideTabBar, object: nil)
//        } else {
//            editButtonItem.tintColor = Asset.blueHighlight.color
//            navigationItem.setRightBarButton(editButtonItem, animated: true)
//            navigationItem.setLeftBarButton(nil, animated: true)
//
//            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .linear) { [weak self] in
//                guard let self = self else { return }
//
//                self.creationButton.alpha = 1
//                self.toolbar.alpha = 0
//            }
//
//            animator.startAnimation()
//
//            NotificationCenter.default.post(name: .showTabBar, object: nil)
//        }
//    }
}

extension CloudDraftsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectAtIndexPath.onNext(indexPath)
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
