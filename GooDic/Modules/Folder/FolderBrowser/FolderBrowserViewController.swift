//
//  FolderBrowserViewController.swift
//  GooDic
//
//  Created by ttvu on 9/11/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

class FolderBrowserViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let distanceToBottom: CGFloat = 25
    }
    
    // MARK: - UI
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var creationButton: UIButton!
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var bottomButton: NSLayoutConstraint!
    var pageViewController: UIPageViewController!
    
    var localVC: FoldersScreenProtocol!
    var cloudVC: (CloudScreenViewProtocol & FoldersScreenProtocol)!
    var viewModelLocal: LocalFoldersViewModel?
    var viewModelLocationSelection: LocalFolderSelectionViewModel?
    var viewModelCloud: CloudFoldersViewModel?
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [localVC, cloudVC]
    }()
    
    // MARK: - Rx & Data
    var disposeBag = DisposeBag()
    var viewModel: FolderBrowserViewModel!
    private let forceChangeSegmentedIndex = PublishSubject<Int>()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindUI()
        self.setupRX()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        self.navigationController?.delegate = self
        
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
    }
    
    func bindUI() {
        creationButton.rx.tap
            .map({ GATracking.Tap.tapCreateNewFolder })
            .subscribe(onNext: GATracking.tap )
            .disposed(by: self.disposeBag)
        
        creationButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.localVC.setEditing(false, animated: true)
                self?.cloudVC.setEditing(false, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        segmentedControl.rx
            .value
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                
                self.updatePage(index: index)
            })
            .disposed(by: self.disposeBag)
        
        pageViewController.rx
            .didTransition
            .subscribe(onNext: { [weak self] (data) in
                guard let self = self else { return }
                
                if data.completed,
                   let currentVC = self.pageViewController.viewControllers?.first,
                   let index = self.orderedViewControllers.firstIndex(of: currentVC) {
                    
                    self.updateSegment(index: index)
                }
            })
            .disposed(by: self.disposeBag)
        
        let heightTabbar = (self.tabBarController?.tabBar.frame.height ?? 0) + AppManager.shared.getHeightSafeArea(type: .bottom) + Constant.distanceToBottom
        
        self.bottomButton.constant = heightTabbar

    }
    
    func bindViewModel() {
        let isCloudTrigger = Driver
            .merge(
                segmentedControl.rx.value.asDriver(),
                forceChangeSegmentedIndex.asDriverOnErrorJustComplete())
            .map({ $0 == 1 })
        
        let input = FolderBrowserViewModel.Input(
            loadData: Driver.just(()),
            viewWillAppear: self.rx.viewWillAppear.asDriver().mapToVoid(),
            createFolderTrigger: creationButton.rx.tap.asDriverOnErrorJustComplete(),
            dismissTrigger: dismissButton.rx.tap.asDriver(),
            isCloudTrigger: isCloudTrigger,
            cloudScreenState: cloudVC.state.asDriverOnErrorJustComplete(),
            userInfo: AppManager.shared.userInfo.asDriver(),
            foldersEvent: self.localVC.foldersEvent.asDriverOnErrorJustComplete()
        )
        
        let output = viewModel.transform(input)
        
        output.title
            .drive(self.rx.title)
            .disposed(by: self.disposeBag)
        
        output.openCloudSegment
            .drive(onNext: { [weak self] isCloudSegment in
                guard let self = self else { return }
                
                self.changeSegment(openCloudSegment: isCloudSegment)
            })
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
        
        output.hideDismissButton
            .asObservable()
            .take(1)
            .bind(onNext: { [weak self] hide in
                if hide {
                    self?.navigationItem.setLeftBarButton(nil, animated: false)
                    self?.view.backgroundColor = Asset.background.color
                } else {
                    self?.view.backgroundColor = Asset.cellBackground.color
                }
            })
            .disposed(by: self.disposeBag)
        
        Driver
            .merge(
                output.createdFolder,
                localVC.didCreateFolder.asDriverOnErrorJustComplete(),
                cloudVC.didCreateFolder.asDriverOnErrorJustComplete())
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .updatedLocalFolder:
                    if self.segmentedControl.selectedSegmentIndex != 0 {
                        self.changeSegment(openCloudSegment: false)
                    }
                    self.viewModelLocal?.updateList.onNext(())
                    
                case .updatedCloudFolder:
                    if self.segmentedControl.selectedSegmentIndex != 1 {
                        self.changeSegment(openCloudSegment: true)
                    }
                    
                default: break
                }
            })
            .disposed(by: self.disposeBag)
        
        output.close
            .drive()
            .disposed(by: self.disposeBag)
        
        output.showPremium
            .drive()
            .disposed(by: self.disposeBag)
        
        tracking(output: output)
    }
    
    private func tracking(output: FolderBrowserViewModel.Output) {
        if self.tabBarController == nil { // is folder selection
            return
        }
        
        // track tap events
        segmentedControl.rx.value
            .filter({ $0 == 1 }) // cloud tab
            .flatMap({ _ in
                self.cloudVC.folderCount.asObserver()
                    .filter({ $0 >= 0})
                    .take(1)
            })
            .bind(onNext: { count in
                GATracking.tap(.tapCloudTabFolderScreen, params: [.foldersInCloudCount(count)])
            })
            .disposed(by: self.disposeBag)
        
        segmentedControl.rx.value
            .filter({ $0 == 0 }) // local tab
            .withLatestFrom(self.localVC.folderCount)
            .bind(onNext: { count in
                GATracking.tap(.tapLocalTabFolderScreen, params: [.foldersInLocalCount(count)])
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupRX() {
        if let local = self.viewModelLocal {
            local.hideButtonCreate.asObservable().bind { [weak self] ishide in
                guard let wSelf = self else { return }
                wSelf.tabBarController?.tabBar.isHidden = ishide
                wSelf.segmentedControl.setEnabled(!ishide, forSegmentAt: 1)
                wSelf.creationButton.isHidden = ishide
            }.disposed(by: self.disposeBag)
        }
        
        if let cloud = self.viewModelCloud {
            cloud.hideButtonCreate.asObservable().bind { [weak self] ishide in
                guard let wSelf = self else { return }
                wSelf.tabBarController?.tabBar.isHidden = ishide
                wSelf.segmentedControl.setEnabled(!ishide, forSegmentAt: 0)
                wSelf.creationButton.isHidden = ishide
            }.disposed(by: self.disposeBag)
        }
        
    }
    
    private func updateSegment(index: Int) {
        self.segmentedControl.selectedSegmentIndex = index
        
        self.forceChangeSegmentedIndex.onNext(index)
    }
    
    private func updatePage(index: Int) {
        if index == 0 {
            GATracking.tap(.tapLocalTabInDraft)
            self.pageViewController.setViewControllers([self.localVC], direction: .reverse, animated: true, completion: nil)
        } else {
            GATracking.tap(.tapCloudTabInDraft)
            self.pageViewController.setViewControllers([self.cloudVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func changeSegment(openCloudSegment: Bool) {
        let index = openCloudSegment ? 1 : 0
        updateSegment(index: index)
        updatePage(index: index)
    }
}

// MARK: - UINavigationControllerDelegate
extension FolderBrowserViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // only show tabBar if viewController is DraftsViewController or FolderBrowserViewController
        self.tabBarController?.tabBar.isHidden = !(viewController is DraftsViewController || viewController is FolderBrowserViewController)
    }
}
