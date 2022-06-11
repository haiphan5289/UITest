//
//  MenuViewController.swift
//  GooDic
//
//  Created by ttvu on 5/18/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GooidSDK
import StoreKit

class MenuViewController: BaseViewController, ViewBindableProtocol {
    
    // MARK: - UI
    @IBOutlet weak var tableView: UITableView!
    var userInfoViewController: UserInfoViewController?
    private let heightOfCellRegisterPremium: CGFloat = 123.0
    
    // MARK: - Rx + Data
    let disposeBag = DisposeBag()
    var viewModel: MenuViewModel!
    let rotateTrigger = PublishSubject<Void>()
    private let eventUpdate: PublishSubject<Void> = PublishSubject.init()
    /// to mark that the app has just been forced orientation
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupUI()
        
        bindUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // in iOS 12.x, the willShow function of navigation delegate is not called if you pop back the view behind while it's presenting any view controller, so I need to force the tab bar to show here
        self.tabBarController?.tabBar.isHidden = false
        self.userInfoViewController?.actionButton.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.eventUpdate.onNext(())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserInfoViewController {
            userInfoViewController = vc
        }
    }
    
    // MARK: - Funcs
    private func setupUI() {
        // handle tabBar to hide or show, we check a view controller which will be showed
        self.navigationController?.delegate = self
        
        let name = String(describing: MenuTableViewCell.self)
        let nameItemPremiumLimited = String(describing: MenuItemPremiumLimitedCell.self)
        let nib = UINib(nibName: name, bundle: Bundle.main)
        let nibMenuItemPremiumLimited = UINib(nibName: nameItemPremiumLimited, bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: MenuTableViewCell.reuseIdentifier)
        tableView.register(nibMenuItemPremiumLimited, forCellReuseIdentifier: MenuItemPremiumLimitedCell.reuseIdentifier)
        tableView.hideEmptyCells()
        tableView.separatorStyle = .none
        navigationController?.navigationBar.tintColor = Asset.textPrimary.color
    }
    
    private func bindUI() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath) in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        AppManager.shared.userInfo
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] userInfo in
                guard let self = self,
                      let headerView = self.tableView.tableHeaderView
                else { return }
                
                UIView.animate(withDuration: 0.3) {
                    self.tableView.beginUpdates()
                    
                    self.userInfoViewController!.userInfo = userInfo
                    let height = self.userInfoViewController!.targetContentSize.height
                    self.userInfoViewController!.updateViewPrenium(userInfo: userInfo)
                    
                    self.tableView.tableHeaderView?.frame.size = CGSize(width: headerView.frame.width, height: height)
                    
                    self.tableView.layoutIfNeeded()
                    self.tableView.endUpdates()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        let actionTrigger = userInfoViewController!.actionButton.rx
            .tap
            .asDriver()
        
        let addDeviceTrigger = userInfoViewController!.addDeviceButton.rx
            .tap
            .asDriver()
        
        let selectCellTrigger = tableView.rx
            .itemSelected
            .asDriver()
        
        let selectFrameTrigger = Driver
            .merge(
                selectCellTrigger.mapToVoid(),
                self.rotateTrigger.asDriverOnErrorJustComplete()
            )
            .withLatestFrom(selectCellTrigger)
            .map { [weak self] (indexPath) -> CGRect? in
                guard let self = self else { return nil }
                
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    return self.tableView.convert(cell.frame, to: self.view)
                }
                
                return nil
            }
            .asDriver()
        
        let input = MenuViewModel.Input(
            loadTrigger: Driver.just(()),
            viewWillAppear: self.rx.viewWillAppear.asDriver().mapToVoid(),
            viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid(),
            actionTrigger: actionTrigger,
            devicesTrigger: addDeviceTrigger,
            selectCellTrigger: tableView.rx.itemSelected.asDriver(),
            selectFrameTrigger: selectFrameTrigger,
            rotateTrigger: rotateTrigger.asDriverOnErrorJustComplete(),
            accountInfoTrigger: self.userInfoViewController!.actionInfoButton.rx.tap.asDriver(),
            eventUpdate: eventUpdate.asDriverOnErrorJustComplete())
        
        let output = viewModel.transform(input)
        
        output.data.drive(tableView.rx.items){(tv, row, model) -> UITableViewCell in
            
            if model.sceneType == .requestPremium {
                let cell = tv.dequeueReusableCell(withIdentifier: MenuItemPremiumLimitedCell.reuseIdentifier, for: IndexPath.init(row: row, section: 0)) as! MenuItemPremiumLimitedCell
                cell.bind(data: model)
                return cell
            } else {
                let cell = tv.dequeueReusableCell(withIdentifier: MenuTableViewCell.reuseIdentifier, for: IndexPath.init(row: row, section: 0)) as! MenuTableViewCell
                cell.bind(data: model)
                return cell
            }

        }.disposed(by: disposeBag)
        
//            .drive(tableView.rx.items(cellIdentifier: MenuTableViewCell.reuseIdentifier,
//                                      cellType: MenuTableViewCell.self),
//                   curriedArgument: { index, model, cell in
//                    cell.bind(data: model)
//                   })
//            .disposed(by: self.disposeBag)
        
        output.getUserName
            .drive()
            .disposed(by: self.disposeBag)
        
        output.checkBillingStatus
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loginLogoutAccount
            .drive()
            .disposed(by: self.disposeBag)
        
        output.presentedDevices
            .drive()
            .disposed(by: self.disposeBag)
        
        output.updatedUIAfterRotation
            .drive()
            .disposed(by: self.disposeBag)
        
        output.accountInfoAction
            .drive()
            .disposed(by: self.disposeBag)
        
        output.detectUserFree.drive().disposed(by: self.disposeBag)
        output.isValidatingServer
            .drive(onNext: { [weak self] validating in
                self?.userInfoViewController?.actionButton.isUserInteractionEnabled = !validating
            })
            .disposed(by: self.disposeBag)
        
        output.eventUpdate.drive().disposed(by: self.disposeBag)
        output.doErrDevices.drive().disposed(by: self.disposeBag)
        output.showPremium.drive().disposed(by: self.disposeBag)
        
        // No.40: the client don't want to show loading view
//        output.showLoading
//            .drive(onNext: { show in
//                if show {
//                    GooLoadingViewController.shared.show()
//                } else {
//                    GooLoadingViewController.shared.hide()
//                }
//            })
//            .disposed(by: self.disposeBag)
        
        tracking(output: output)
    }
    
    private func tracking(output: MenuViewModel.Output) {
        // track scene
        GATracking.scene(self.sceneType)
        
        // track tap events
        output.selectedCell
            .drive(onNext: { (action) in
                switch action {
                case .share(let urlString):
                    if let _ = URL(string: urlString) {
                        GATracking.tap(.tapShareService)
                    } else {
                        GATracking.tap(.tapSharePcUrl)
                    }
                case .openGooTwitter:
                    GATracking.tap(.tapTwitter)
                default:
                    return
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

// MARK: - Orientation
extension MenuViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { (context) in
            self.rotateTrigger.onNext(())
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension MenuViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // only show tabBar if viewController is MenuViewController
        self.tabBarController?.tabBar.isHidden = !(viewController is MenuViewController)
    }
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if AppManager.shared.userInfo.value?.billingStatus != .paid {
            if indexPath.row == 0 {
                return heightOfCellRegisterPremium
            }
        }
        return UITableView.automaticDimension
    }
}
