//
//  DraftsViewController.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DraftsViewController: BaseViewController, ViewBindableProtocol {

    // MARK: - // MARK: - UI
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var creationButton: UIButton!
    @IBOutlet weak var deleteBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var moveToBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var innerVC: (MultiSelectionViewProtocol & CloudScreenViewProtocol)!
    
    lazy var tutorialAddDocumentPopup: UIImageView = {
        let tutorial = UIImageView(image: Asset.imgTutoCreation.image)
        tutorial.addTapGesture { [weak self] (gesture) in
            self?.interactWithAddNewDocumentTutorial.onNext(())
        }
        
        return tutorial
    }()
    
    var editAnchor: UIView? // using to anchor the editing mode tooltip
    lazy var tutorialEditModePopup: UIImageView = {
        let tutorial = UIImageView(image: Asset.imgTutoEdit.image)
        tutorial.addTapGesture { [weak self] (gesture) in
            self?.interactWithEditModeTutorial.onNext(())
        }
        
        return tutorial
    }()
    
    // a placeholder of bar button, the purpose is to limit the length of title view
    lazy var emptyBarButtonItem: UIBarButtonItem = {
        let button = createBarButtonItem(with: L10n.Draft.BarButtonItem.edit)
        button.tintColor = .clear
        button.isEnabled = false
        return button
    }()
    
    lazy var selectOrDeselectAllBarButtonItem: UIBarButtonItem = {
        createBarButtonItem(with: L10n.Draft.BarButtonItem.selectAll)
    }()
    
    lazy var cancelBarButtonItem: UIBarButtonItem = {
        createBarButtonItem(with: L10n.Draft.BarButtonItem.cancel)
    }()
    
    // MARK: - Rx + Data
    private var disposeBag = DisposeBag()
    var viewModel: DraftsViewModel!
    var interactWithAddNewDocumentTutorial = PublishSubject<Void>()
    var interactWithEditModeTutorial = PublishSubject<Void>()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        bindUI()
        self.setupRX()
    }
    
    deinit {
        print("===== Home Draft")
    }
    
    // MARK: - Funcs
    private func setupUI() {
        // handle tabBar to hide or show, we check a view controller which will be showed
        if self.navigationController?.delegate == nil {
            self.navigationController?.delegate = self
        }
        
        navigationController?.navigationBar.tintColor = Asset.textPrimary.color
        
        setEditing(false, animated: false)
        
        // setup inner view
        self.addChild(innerVC)
        let innerView = innerVC.view!
        self.containerView.addSubview(innerView)
        innerVC.didMove(toParent: self)
        
        innerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
            innerView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
            innerView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor),
            innerView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor)
        ])
        
        editButtonItem.tintColor = Asset.blueHighlight.color
    }
    
    private func bindUI() {
        let backToNormalModelTrigger = innerVC.backToNormalModelTrigger
            .asDriverOnErrorJustComplete()
//            .map({ self.isEditing })
            .map({ [weak self] _ -> Bool in
                guard let wSelf = self else { return false }
                return wSelf.isEditing
            })
            .filter({ $0 })
            .mapToVoid()
        
        innerVC.selectionButtonTitle
            .asDriverOnErrorJustComplete()
            .drive(self.selectOrDeselectAllBarButtonItem.rx.title)
            .disposed(by: self.disposeBag)
        
        let changeEditModeTrigger = Driver
            .merge(
                editButtonItem.rx.tap.asDriver(),
                cancelBarButtonItem.rx.tap.asDriver(),
                backToNormalModelTrigger)
        
        let dataHasChanged = self.innerVC
            .itemCount
            .map({ $0 > 0 })
            .asDriverOnErrorJustComplete()
        
        changeEditModeTrigger
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.setEditing(!self.isEditing, animated: true)
                
                self.innerVC.editMode.onNext(self.isEditing)
            })
            .disposed(by: self.disposeBag)
        
        // enable / disable the edit button
        Driver
            .merge(
                changeEditModeTrigger,
                dataHasChanged.mapToVoid())
            .withLatestFrom(dataHasChanged)
            .map({ [weak self] hasData -> EditState in
                guard let self = self else { return .none }
                
                return hasData ? (self.isEditing ? EditState.isEditing : .canEdit) : .none
            })
            .distinctUntilChanged()
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .canEdit:
                    self.navigationItem.setRightBarButton(self.editButtonItem, animated: true)
                case .isEditing:
                    self.navigationItem.setRightBarButton(self.cancelBarButtonItem, animated: true)
                case .none:
                    self.navigationItem.setRightBarButton(nil, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
        
        selectOrDeselectAllBarButtonItem.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.innerVC.selectOrDeselectAllItemsTrigger.onNext(())
            })
            .disposed(by: self.disposeBag)
        
        deleteBarButtonItem.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.innerVC.binItemsTrigger.onNext(())
            })
            .disposed(by: self.disposeBag)
        
        moveToBarButtonItem.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.innerVC.moveItemsTrigger.onNext(())
            })
            .disposed(by: self.disposeBag)
        
        // enable / disable both buttons on toolbar
        Driver
            .merge(
                selectOrDeselectAllBarButtonItem.rx.tap.asDriverOnErrorJustComplete(),
                self.innerVC.selectedItems.asDriverOnErrorJustComplete().mapToVoid())
            .withLatestFrom(self.innerVC.selectedItems.asDriverOnErrorJustComplete())
            .map({ $0.count > 0 })
            .drive(onNext: { [weak self] (isEnabled) in
                self?.deleteBarButtonItem.isEnabled = isEnabled
                self?.moveToBarButtonItem.isEnabled = isEnabled
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        let editingModeTrigger = Driver
            .merge(
                editButtonItem.rx.tap.asDriver(),
                cancelBarButtonItem.rx.tap.asDriver(),
                innerVC.backToNormalModelTrigger.asDriverOnErrorJustComplete())
            .map({ [weak self] _ -> Bool in
                guard let wSelf = self else { return false }
                return wSelf.isEditing
            })
//            .map({ self.isEditing })
            .startWith(false)
        
        let numberOfSelectedDrafts = innerVC.selectedItems
            .map({ $0.count })
            .asDriverOnErrorJustComplete()
        
        let checkedNewUserTrigger = AppManager.shared.checkedNewUser
            .filter({ $0 })
            .asDriverOnErrorJustComplete()
        
        let input = DraftsViewModel.Input(
            loadDataTrigger: Driver.just(()),
            openCreationTrigger: creationButton.rx.tap.asDriverOnErrorJustComplete(),
            selectOrDeselectAllDraftsTrigger: selectOrDeselectAllBarButtonItem.rx.tap.asDriverOnErrorJustComplete(),
             editingModeTrigger: editingModeTrigger,
            numberOfSelectedDrafts: numberOfSelectedDrafts,
            title: self.innerVC.hasChangedTitle.asDriverOnErrorJustComplete(),
            useInfo: AppManager.shared.userInfo.asDriver(),
            cloudScreenState: innerVC.state.asDriverOnErrorJustComplete(),
            hasData: innerVC.itemCount.map({ $0 > 0 }).asDriverOnErrorJustComplete(),
            viewDidAppear: self.rx.viewDidAppear.asDriver().mapToVoid(),
            viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid(),
            viewDidLayoutSubviewsTrigger: self.rx.viewDidLayoutSubviews.asDriver().mapToVoid(),
            showedSwipeDocumentTooltip: innerVC.showedSwipeDocumentTooltip.asDriverOnErrorJustComplete(),
            checkedNewUserTrigger: checkedNewUserTrigger,
            touchAddNewDocumentTooltipTrigger: interactWithAddNewDocumentTutorial.asDriverOnErrorJustComplete(),
            touchEditModeTooltipTrigger: interactWithEditModeTutorial.asDriverOnErrorJustComplete(),
            eventSelectDraftOver: self.innerVC.eventSelectDraftOver.asDriverOnErrorJustComplete())
        
        let output = viewModel.transform(input)
        
        Driver
            .combineLatest(output.title, output.isCloud)
            .drive(onNext: { [weak self] (title, isCloud) in
                guard let self = self else { return }
                let style = [NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 18)]
                let attString = NSMutableAttributedString(string: title, attributes: style)
                
                if isCloud {
                    self.navigationBarCloudTitle.attributedText = attString
                } else {
                    self.navigationBarTitle.attributedText = attString
                }
            })
            .disposed(by: self.disposeBag)
            
        output.openCreation
            .drive()
            .disposed(by: self.disposeBag)
        
        output.hideCreationButton
            .drive(self.creationButton.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        output.showAddDocumentTooltip
            .drive(onNext: { [weak self] (show) in
                guard let self = self else { return }
                
                if show {
                    var config = UIView.AnimConfig()
                    config.popupAnchorPoint = UIView.AnchorPoint.anchor(
                        CGPoint(x: self.tutorialAddDocumentPopup.frame.width - self.creationButton.frame.width * 0.5,
                                y: self.tutorialAddDocumentPopup.frame.height + 10))
                    config.targetAnchorPoint = UIView.AnchorPoint.centerTop
                    
                    self.view.show(popup: self.tutorialAddDocumentPopup, targetRect: self.creationButton.frame, config: config, controlView: self.creationButton)
                } else {
                    self.view.dismiss(popup: self.tutorialAddDocumentPopup, verticalAnim: 5)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.showEditModeTooltip
            .drive(onNext: { [weak self] show in
                guard
                    let self = self,
                    let buttonView = self.editButtonItem.view
                else { return }
                
                if show && self.navigationItem.rightBarButtonItem != nil {
                    let frameInView = buttonView.convert(buttonView.bounds, to: self.view)
                    
                    // reference to XD file
                    let paddingTop: CGFloat = 6.0
                    let pointingCornerPaddingRight: CGFloat = 24.0
                    let popupAnchorPoint = CGPoint(x: self.tutorialEditModePopup.bounds.width - pointingCornerPaddingRight, y: 0)
                    let targetAnchorPoint = CGPoint(x: frameInView.midX, y: frameInView.maxY + paddingTop)
                    
                    if self.editAnchor == nil {
                        self.editAnchor = UIView(frame: CGRect(origin: targetAnchorPoint, size: .zero))
                        self.view.addSubview(self.editAnchor!)
                        self.editAnchor?.translatesAutoresizingMaskIntoConstraints = false
                        
                        let rightSafeArea = self.view.safeAreaInsets.right
                        let topSafeArea = self.view.safeAreaInsets.top
                        
                        NSLayoutConstraint.activate([
                            self.editAnchor!.widthAnchor.constraint(equalToConstant: 0),
                            self.editAnchor!.heightAnchor.constraint(equalToConstant: 0),
                            self.editAnchor!.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -self.view.bounds.width + self.editAnchor!.frame.maxX + rightSafeArea),
                            self.editAnchor!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.editAnchor!.frame.minY - topSafeArea)
                        ])
                    }
                    
                    var config = UIView.AnimConfig()
                    config.popupAnchorPoint = UIView.AnchorPoint.anchor(popupAnchorPoint)
                    config.targetAnchorPoint = UIView.AnchorPoint.anchor(targetAnchorPoint)
                    
                    self.view.show(popup: self.tutorialEditModePopup, targetRect: frameInView, config: config, controlView: self.editAnchor!)
                } else {
                    self.view.dismiss(popup: self.tutorialEditModePopup, verticalAnim: -5)
                }
            })
            .disposed(by: self.disposeBag)
        
        output.autoHideToolTips
            .drive()
            .disposed(by: self.disposeBag)
        
        output.eventSelectDraftOver.drive().disposed(by: self.disposeBag)
        
        tracking(output: output)
    }
    
    private func setupRX() {
        self.innerVC.hideButtonEventTrigger.asObservable()
            .withLatestFrom(self.innerVC.itemCount, resultSelector: { (total: $1, ishide: $0) })
            .bind { [weak self] total, ishide in
            guard let wSelf = self else { return }
            if ishide {
                wSelf.navigationItem.setRightBarButton(nil, animated: true)
            } else {
                wSelf.navigationItem.setRightBarButton( (total <= 0) ? nil : wSelf.editButtonItem, animated: true)
            }
            
            wSelf.toolbar.isHidden = ishide
            wSelf.tabBarController?.tabBar.isHidden = ishide
            wSelf.creationButton.isHidden = ishide
        }.disposed(by: self.disposeBag)
    }
    
    private func tracking(output: DraftsViewModel.Output) {
        // track tap
        creationButton.rx.tap
            .map({ GATracking.Tap.tapCreateDraft })
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        let animationDuration: TimeInterval = 0.2
        if editing {
            navigationItem.setLeftBarButton(selectOrDeselectAllBarButtonItem, animated: true)

            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .linear) { [weak self] in
                guard let self = self else { return }
                
                self.toolbar.alpha = 1
            }
            
            animator.startAnimation()
            
            NotificationCenter.default.post(name: .hideTabBar, object: nil)
        } else {
            navigationItem.setLeftBarButton(nil, animated: true)
            
            let animator = UIViewPropertyAnimator(duration: animationDuration, curve: .linear) { [weak self] in
                guard let self = self else { return }

                self.toolbar.alpha = 1
            }
            
            animator.startAnimation()
            
            NotificationCenter.default.post(name: .showTabBar, object: nil)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // update toolbar's frame as soon as rotating
        self.toolbar.invalidateIntrinsicContentSize()
    }
}

extension DraftsViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // only show tabBar if viewController is DraftListViewController
//        self.tabBarController?.tabBar.isHidden = !(viewController is DraftListViewController)
    }
}
