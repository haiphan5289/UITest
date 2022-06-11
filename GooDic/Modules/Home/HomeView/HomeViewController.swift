//
//  HomeViewController.swift
//  GooDic
//
//  Created by ttvu on 12/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAnalytics
import FirebaseInAppMessaging

enum EditState {
    case isEditing
    case canEdit
    case none
}

class HomeViewController: BaseViewController, ViewBindableProtocol {
    
    // MARK: - UI
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var creationButton: UIButton!
    @IBOutlet weak var deleteBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var moveToBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    var pageViewController: UIPageViewController!
    private let forceChangeSegmentedIndex = PublishSubject<Int>()
    var topBannerView: HomeBannerView!
    
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
    
    lazy var selectOrDeselectAllBarButtonItem: UIBarButtonItem = {
        createBarButtonItem(with: L10n.Draft.BarButtonItem.selectAll)
    }()
    
    lazy var cancelBarButtonItem: UIBarButtonItem = {
        createBarButtonItem(with: L10n.Draft.BarButtonItem.cancel)
    }()
    
    var localVC: LocalDraftsViewController!
    var cloudVC: CloudDraftsViewController!
    private(set) var localSeparator: UIView!
    private(set) var cloudSeparator: UIView!
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [localVC, cloudVC]
    }()
    
    // MARK: - Data + Rx
    var disposeBag = DisposeBag()
    var viewModel: HomeViewModel!
    var interactWithAddNewDocumentTutorial = PublishSubject<Void>()
    var interactWithEditModeTutorial = PublishSubject<Void>()
    private let tapCloudTab = PublishSubject<Void>()
    private let tapLocalTab = PublishSubject<Void>()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        bindUI()
        self.setupRX()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // allow (enable) render in-app messaging
        InAppMessaging.inAppMessaging().messageDisplaySuppressed = false
        displayTopBannerIfNeed(isPrepareTransit: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // send event to open in-app messaging if needed
        InAppMessaging.inAppMessaging().triggerEvent(GlobalConstant.iamOpenHomeViewTrigger)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // disallow (disable) render in-app messaging
        InAppMessaging.inAppMessaging().messageDisplaySuppressed = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        displayTopBannerIfNeed(isPrepareTransit: true)
    }
      
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UIPageViewController {
            pageViewController = vc
            
            pageViewController.setViewControllers([localVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    // MARK: - Funcs
    func setupUI() {
        // handle tabBar to hide or show, we check a view controller which will be showed
        if self.navigationController?.delegate == nil {
            self.navigationController?.delegate = self
        }
        
        // setup segmented control
        self.segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 13.0),
            NSAttributedString.Key.foregroundColor: Asset.textPrimary.color
        ], for: .normal)
        self.segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 14.0),
            NSAttributedString.Key.foregroundColor: UIColor.black,
        ], for: .selected)
        self.segmentedControl.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: Asset.textGreyDisable.color,
        ], for: .disabled)
        
        self.segmentedControl.tintColor = Asset.segmentedColor.color
        self.localSeparator = self.localVC.view.addSeparator(at: .top, color: Asset.cellSeparator.color)
        self.cloudSeparator = self.cloudVC.view.addSeparator(at: .top, color: Asset.cellSeparator.color)
        
        editButtonItem.tintColor = Asset.blueHighlight.color
        setEditing(false, animated: false)
        
        let customView = HomeBannerView(frame: CGRect.zero)
        customView.translatesAutoresizingMaskIntoConstraints = false
        self.topBannerView = customView
    }
    
    func bindUI() {
        creationButton.rx.tap
            .map({ GATracking.Tap.tapCreateDraft })
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
        
        self.localVC.itemCount
            .map({ $0 <= 0 })
            .asDriverOnErrorJustComplete()
            .drive(self.localSeparator.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        self.cloudVC.itemCount
            .map({ $0 <= 0 })
            .asDriverOnErrorJustComplete()
            .drive(self.cloudSeparator.rx.isHidden)
            .disposed(by: self.disposeBag)
        
        
        segmentedControl.rx
            .value
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                if index == 0 {
                    self.pageViewController.setViewControllers([self.localVC], direction: .reverse, animated: true, completion: nil)
                } else {
                    self.pageViewController.setViewControllers([self.cloudVC], direction: .forward, animated: true, completion: nil)
                }
            })
            .disposed(by: self.disposeBag)
        
        segmentedControl.rx.value.bind { [weak self] (idx) in
            guard let wSelf = self else { return }
            if idx == 0 {
                wSelf.tapLocalTab.onNext(())
            } else {
                wSelf.tapCloudTab.onNext(())
            }
        }.disposed(by: disposeBag)
        
        let backToNormalModelTrigger = Driver
            .merge(
                localVC.backToNormalModelTrigger.asDriverOnErrorJustComplete(),
                cloudVC.backToNormalModelTrigger.asDriverOnErrorJustComplete())
            .map({ self.isEditing })
            .filter({ $0 })
            .mapToVoid()
        
        let isCloudTrigger = Driver
            .merge(
                segmentedControl.rx.value.asDriver(),
                forceChangeSegmentedIndex.asDriverOnErrorJustComplete())
            .map({ $0 == 1 })
        
        let changeEditModeTrigger = Driver
            .merge(
                editButtonItem.rx.tap.asDriver(),
                cancelBarButtonItem.rx.tap.asDriver(),
                backToNormalModelTrigger)
        
        let dataHasChanged = Driver
            .combineLatest(
                isCloudTrigger,
                self.localVC.itemCount.map({ $0 > 0 }).asDriverOnErrorJustComplete(),
                self.cloudVC.itemCount.map({ $0 > 0 }).asDriverOnErrorJustComplete(),
                resultSelector: {(isCloud: $0, localValue: $1, cloudValue: $2 )})
        
        changeEditModeTrigger
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.setEditing(!self.isEditing, animated: true)
                
                self.localVC.editMode.onNext(self.isEditing)
                self.cloudVC.editMode.onNext(self.isEditing)
            })
            .disposed(by: self.disposeBag)
        
        // update the edit button
        Driver
            .merge(
                changeEditModeTrigger,
                dataHasChanged.mapToVoid())
            .withLatestFrom(dataHasChanged)
            .map({ $0.isCloud ? $0.cloudValue : $0.localValue })
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
                    self.navigationItem.setRightBarButton(nil, animated: false)
                }
            })
            .disposed(by: self.disposeBag)
        
        selectOrDeselectAllBarButtonItem.rx.tap
            .withLatestFrom(isCloudTrigger)
            .subscribe(onNext: { [weak self] isCloud in
                guard let self = self else { return }
                
                if isCloud {
                    self.cloudVC.selectOrDeselectAllItemsTrigger.onNext(())
                } else {
                    self.localVC.selectOrDeselectAllItemsTrigger.onNext(())
                }
            })
            .disposed(by: self.disposeBag)
        
        deleteBarButtonItem.rx.tap
            .withLatestFrom(isCloudTrigger)
            .subscribe(onNext: { [weak self] isCloud in
                guard let self = self else { return }
                
                if isCloud {
                    self.cloudVC.binItemsTrigger.onNext(())
                } else {
                    self.localVC.binItemsTrigger.onNext(())
                }
            })
            .disposed(by: self.disposeBag)
        
        moveToBarButtonItem.rx.tap
            .withLatestFrom(isCloudTrigger)
            .subscribe(onNext: { [weak self] isCloud in
                guard let self = self else { return }
                
                if isCloud {
                    self.cloudVC.moveItemsTrigger.onNext(())
                } else {
                    self.localVC.moveItemsTrigger.onNext(())
                }
            })
            .disposed(by: self.disposeBag)
        
        // enable / disable both buttons on toolbar
        Driver.merge(
            segmentedControl.rx.value.asDriverOnErrorJustComplete().mapToVoid(),
            selectOrDeselectAllBarButtonItem.rx.tap.asDriverOnErrorJustComplete())
            .withLatestFrom(isCloudTrigger)
            .flatMap({ isCloud -> Driver<[IndexPath]> in
                if isCloud {
                    return self.cloudVC.selectedItems.asDriverOnErrorJustComplete()
                }
                
                return self.localVC.selectedItems.asDriverOnErrorJustComplete()
            })
            .map({ $0.count > 0 })
            .drive(onNext: { [weak self] (isEnabled) in
                self?.deleteBarButtonItem.isEnabled = isEnabled
                self?.moveToBarButtonItem.isEnabled = isEnabled
            })
            .disposed(by: self.disposeBag)
        
        pageViewController.rx
            .didTransition
            .subscribe(onNext: { [weak self] (data) in
                guard let self = self else { return }
                
                if data.completed,
                   let currentVC = self.pageViewController.viewControllers?.first,
                   let index = self.orderedViewControllers.firstIndex(of: currentVC) {
                    
                    self.segmentedControl.selectedSegmentIndex = index
                }
            })
            .disposed(by: self.disposeBag)
        
        let hide = Observable.merge(self.localVC.hideButtonEventTrigger.startWith(false), self.cloudVC.hideButtonEventTrigger.startWith(false))
        
        self.topBannerView.closeButton.rx.tap
            .withLatestFrom(hide, resultSelector: { $1 })
            .filter{ !$0 }
            .mapToVoid()
            .bind(onNext: { [weak self] _ in
                self?.hideTopBanner()
                GATracking.tap(.tapOriginalInfoClose)
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        let isCloudTrigger = Driver
            .merge(
                segmentedControl.rx.value.asDriver(),
                forceChangeSegmentedIndex.asDriverOnErrorJustComplete())
            .map({ $0 == 1 })
        
        let editingModeTrigger = Driver
            .merge(
                editButtonItem.rx.tap.asDriver(),
                cancelBarButtonItem.rx.tap.asDriver(),
                localVC.backToNormalModelTrigger.asDriverOnErrorJustComplete(),
                cloudVC.backToNormalModelTrigger.asDriverOnErrorJustComplete())
            .map({ self.isEditing })
            .startWith(false)
        
        let localSelectedDraftsCount = self.localVC
            .selectedItems
            .map({ $0.count })
            .asDriverOnErrorJustComplete()
        
        let cloudSelectedDraftsCount = self.cloudVC
            .selectedItems
            .map({ $0.count })
            .asDriverOnErrorJustComplete()
        
        let checkedNewUserTrigger = AppManager.shared.checkedNewUser
            .filter({ $0 })
            .asDriverOnErrorJustComplete()
        
        let showedSwipeDocumentTooltip = Driver
            .merge(
                localVC.showedSwipeDocumentTooltip.asDriverOnErrorJustComplete(),
                cloudVC.showedSwipeDocumentTooltip.asDriverOnErrorJustComplete()
            )
        
        let eventSelectDraftOver = Observable.merge(self.localVC.eventSelectDraftOver, self.cloudVC.eventSelectDraftOver)
            .asDriverOnErrorJustComplete()
        
        let hide = Observable.merge(self.localVC.hideButtonEventTrigger.startWith(false), self.cloudVC.hideButtonEventTrigger.startWith(false))
        
        let buttonInfoBannerTrigger = topBannerView.actionButton.rx.tap
            .withLatestFrom(hide, resultSelector: { $1 })
            .filter{ !$0 }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let buttonCloseBannerTrigger = topBannerView.closeButton.rx.tap
            .withLatestFrom(hide, resultSelector: { $1 })
            .filter{ !$0 }
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let input = HomeViewModel.Input(
            loadDataTrigger: Driver.just(()),
            viewDidAppear: self.rx.viewDidAppear.asDriver().mapToVoid(),
            viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid(),
            isCloudTrigger: isCloudTrigger,
            openCreationTrigger: creationButton.rx.tap.asDriverOnErrorJustComplete(),
            userInfo: AppManager.shared.userInfo.asDriver(),
            cloudScreenState: cloudVC.state.asDriverOnErrorJustComplete(),
            editingModeTrigger: editingModeTrigger,
            numberOfSelectedDrafts: localSelectedDraftsCount,
            localSelectionButtonTitle: localVC.selectionButtonTitle.asDriverOnErrorJustComplete(),
            numberOfSelectedCloudDrafts: cloudSelectedDraftsCount,
            cloudSelectionButtonTitle: cloudVC.selectionButtonTitle.asDriverOnErrorJustComplete(),
            buttonInfoBannerTrigger: buttonInfoBannerTrigger,
            buttonCloseBannerTrigger: buttonCloseBannerTrigger,
            hasLocalData: localVC.itemCount.map({ $0 > 0 }).asDriverOnErrorJustComplete(),
            hasCloudData: cloudVC.itemCount.map({ $0 > 0 }).asDriverOnErrorJustComplete(),
            viewDidLayoutSubviewsTrigger: self.rx.viewDidLayoutSubviews.asDriver(),
            showedSwipeDocumentTooltip: showedSwipeDocumentTooltip,
            checkedNewUserTrigger: checkedNewUserTrigger,
            touchAddNewDocumentTooltipTrigger: interactWithAddNewDocumentTutorial.asDriverOnErrorJustComplete(),
            touchEditModeTooltipTrigger: interactWithEditModeTutorial.asDriverOnErrorJustComplete(),
            eventSelectDraftOver: eventSelectDraftOver
        )
        
        let output = viewModel.transform(input)
        
        output.title
            .drive(onNext: { [weak self] (title) in
                guard let self = self else { return }
                let atts = [NSAttributedString.Key.font: UIFont.hiraginoSansW6(size: 18)]
                self.navigationBarTitle.attributedText = NSAttributedString(string: title, attributes: atts)
            })
            .disposed(by: self.disposeBag)
        
        output.selectionButtonTitle
            .drive(self.selectOrDeselectAllBarButtonItem.rx.title)
            .disposed(by: self.disposeBag)
        
        output.openCreation
            .drive()
            .disposed(by: self.disposeBag)
        
        output.hideCreationButton
            .drive(onNext: { [weak self] hide in
                guard let self = self else { return }
                
                self.creationButton.isEnabled = !hide
                UIView.animate(withDuration: 0.3) {
                    self.creationButton.alpha = hide ? 0 : 1
                }
            })
            .disposed(by: self.disposeBag)
        
        output.enableLocalTab
            .drive(onNext: { [weak self] enable in
                self?.segmentedControl.setEnabled(enable, forSegmentAt: 0)
            })
            .disposed(by: self.disposeBag)
        
        output.enableCloudTab
            .drive(onNext: { [weak self] enable in
                self?.segmentedControl.setEnabled(enable, forSegmentAt: 1)
            })
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
            .asObservable()
            .delay(.milliseconds(200), scheduler: MainScheduler.instance) // we should have a little bit of delay time to the view has been set up (it is a private API)
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] show in
                guard
                    let self = self,
                    let buttonView = self.editButtonItem.view
                else { return }
                
                if show && self.navigationItem.rightBarButtonItem != nil {
                    let frameInView = buttonView.convert(buttonView.bounds, to: self.view)
                    
                    if frameInView.origin.x == 0 {
                        return
                    }
                    
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
        
        output.titleForBanner
            .drive(onNext: { [weak self] (title) in
                guard let self = self else { return }
                guard let titleBanner = title else {
                    self.hideTopBanner()
                    return
                }
                self.showTopBannerWith(title: titleBanner)
            })
            .disposed(by: self.disposeBag)
        
        output.buttonCloseBannerAction
            .drive()
            .disposed(by: self.disposeBag)
        
        output.buttonInfoBannerAction
            .drive()
            .disposed(by: self.disposeBag)
        
        tracking(output: output)
    }
    
    private func setupRX() {
        self.localVC.hideButtonEventTrigger.asObservable().bind { [weak self] ishide in
            guard let wSelf = self else { return }
            if ishide {
                wSelf.navigationItem.setRightBarButton(nil, animated: true)
            } else {
                wSelf.navigationItem.setRightBarButton( (wSelf.localVC.viewModel.dataSource.drafts.count <= 0) ? nil : wSelf.editButtonItem, animated: true)
            }
            
            wSelf.toolbar.isHidden = ishide
            wSelf.tabBarController?.tabBar.isHidden = ishide
            wSelf.segmentedControl.setEnabled(!ishide, forSegmentAt: 1)
            wSelf.creationButton.isHidden = ishide
            wSelf.topBannerView.closeButton.isEnabled = !ishide
        }.disposed(by: self.disposeBag)
        
        self.cloudVC.hideButtonEventTrigger.asObservable().bind { [weak self] ishide in
            guard let wSelf = self else { return }
            if ishide {
                wSelf.navigationItem.setRightBarButton(nil, animated: true)
            } else {
                wSelf.navigationItem.setRightBarButton( (wSelf.cloudVC.documents.count <= 0) ? nil : wSelf.editButtonItem, animated: true)
            }
            
            wSelf.toolbar.isHidden = ishide
            wSelf.tabBarController?.tabBar.isHidden = ishide
            wSelf.segmentedControl.setEnabled(!ishide, forSegmentAt: 0)
            wSelf.creationButton.isHidden = ishide
            wSelf.topBannerView.closeButton.isEnabled = !ishide
        }.disposed(by: self.disposeBag)
    }
    
    private func tracking(output: HomeViewModel.Output) {
        // track scene
        output.isLogin
            .map({ $0 ? GATracking.LoginStatus.login : GATracking.LoginStatus.logout })
            .drive(onNext: { status in
                let userStatus: GATracking.UserStatus = status == .logout
                    ? .other
                    : AppManager.shared.billingInfo.value.billingStatus == .paid
                    ? .premium
                    : .regular
                        
                GATracking.scene(.openHomeScreen, params: [.loginStatus(status), .userStatus(userStatus)])
                
                if AppSettings.firstInHome {
                    let gooLoginType: GATracking.GooLoginType = status == .logout
                        ? .logout
                        : .login
                    GATracking.sendUserProperties(property: .gooLoginType(gooLoginType))
                    AppSettings.firstInHome = false
                }
                
                let userStatus2: GATracking.UserStatus2 = status == .logout
                    ? .other
                    : AppManager.shared.billingInfo.value.billingStatus == .paid
                    ? .premium
                    : .regular
                GATracking.sendUserProperties(property: .userStatus2(userStatus2))
            })
            .disposed(by: self.disposeBag)
        
        // track tap
        segmentedControl.rx.value
            .filter({ $0 == 1 }) // cloud tab
            .flatMap({ _ in
                self.cloudVC.itemCount.asObservable()
                    .filter({ $0 >= 0})
                    .take(1)
            })
            .bind(onNext: { count in
                GATracking.tap(.tapCloudTabHomeScreen, params: [.draftsInCloudCount(count)])
            })
            .disposed(by: self.disposeBag)
        
        segmentedControl.rx.value
            .filter({ $0 == 0 }) // local tab
            .withLatestFrom(self.localVC.itemCount)
            .bind(onNext: { count in
                GATracking.tap(.tapLocalTabHomeScreen, params: [.draftsInLocalCount(count)])
            })
            .disposed(by: self.disposeBag)
        
        creationButton.rx.tap
            .bind(onNext: {
                GATracking.tap(.tapCreateDraft)
            })
            .disposed(by: self.disposeBag)
        
        editButtonItem.rx.tap
            .map({ self.isEditing })
            .filter({ $0 })
            .bind(onNext: { _ in
                GATracking.tap(.tapEdit)
            })
            .disposed(by: self.disposeBag)
        
        output.eventSelectDraftOver.drive().disposed(by: disposeBag)
        output.showPremium.drive().disposed(by: disposeBag)
        
        topBannerView.actionButton.rx.tap
            .bind(onNext: {
                GATracking.tap(.tapOriginalInfo)
            })
            .disposed(by: self.disposeBag)
        
        if let settingFont = AppSettings.settingFont {
            GATracking.tap(.settingFont, params: [.font(settingFont.name.toTracking), .fontSize(settingFont.size.toTracking)])
        }
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
    
    private func updateSegment(index: Int) {
        self.segmentedControl.selectedSegmentIndex = index
        self.forceChangeSegmentedIndex.onNext(index)
    }
    
    private func updatePage(index: Int) {
        if index == 0 {
            self.pageViewController.setViewControllers([self.localVC], direction: .reverse, animated: true, completion: nil)
        } else {
            self.pageViewController.setViewControllers([self.cloudVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func changeSegment(openCloudSegment: Bool) {
        let index = openCloudSegment ? 1 : 0
        updateSegment(index: index)
        updatePage(index: index)
    }
    
    private func showTopBannerWith(title: String) {
        if self.topBannerView?.superview != nil {
            topBannerView.originalContent = title
            topBannerView.titleLabel.text = title
            return
        }
        if #available(iOS 13.0, *) {
            self.navigationController?.additionalSafeAreaInsets.top = HomeBannerView.heightDefault
        } else {
            self.navigationController?.additionalSafeAreaInsets.top = HomeBannerView.heightDefault + (self.navigationController?.navigationBar.frame.height ?? 0)
        }
        self.navigationController?.view.addSubview(topBannerView)
        topBannerView.titleLabel.text = title
        topBannerView.originalContent = title
        if let nc = navigationController as? BaseNavigationController {
            nc.heightExtend = HomeBannerView.heightDefault
            topBannerView.leadingAnchor.constraint(equalTo: nc.view.leadingAnchor, constant: 0).isActive = true
            topBannerView.trailingAnchor.constraint(equalTo: nc.view.trailingAnchor, constant: 0).isActive = true
            topBannerView.bottomAnchor.constraint(equalTo: nc.navigationBar.topAnchor, constant: 0).isActive = true
            topBannerView.heightAnchor.constraint(equalToConstant: HomeBannerView.heightDefault).isActive = true
        }
    }
    
    private func hideTopBanner() {
        if self.topBannerView.superview == nil {
            return
        }
        self.topBannerView.removeFromSuperview()
        self.navigationController?.additionalSafeAreaInsets = .zero
        if let nc = navigationController as? BaseNavigationController {
            nc.heightExtend = 0
        }
    }
    
    private func displayTopBannerIfNeed(isPrepareTransit: Bool) {
        if self.topBannerView.superview == nil {
            return
        }
        
        self.topBannerView.isHidden = isPrepareTransit
        if let nc = navigationController as? BaseNavigationController {
            nc.heightExtend = isPrepareTransit ? 0 : HomeBannerView.heightDefault
        }
        if isPrepareTransit {
            self.navigationController?.additionalSafeAreaInsets = .zero
            return
        }
        if #available(iOS 13.0, *) {
            self.navigationController?.additionalSafeAreaInsets.top = HomeBannerView.heightDefault
        } else {
            self.navigationController?.additionalSafeAreaInsets.top = HomeBannerView.heightDefault + (self.navigationController?.navigationBar.frame.height ?? 0)
        }
    }
}

extension HomeViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // only show tabBar if viewController is HomeViewController
        self.tabBarController?.tabBar.isHidden = !(viewController is HomeViewController)
    }
}
