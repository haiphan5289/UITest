//
//  RegisterDeviceViewController.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum TypeRegisterDevice {
    case agreement
    case other
}

enum TapRegisterScreen {
    case addDevice(String)
    case removeDevice(DeviceInfo)
    case ignore
    case getListDevice
}

class RegisterDeviceViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let limitDevice = GlobalConstant.limitDevice
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vNote: UIView!
    @IBOutlet weak var lbNote: UILabel!
    @IBOutlet weak var vRelease: UIView!
    @IBOutlet weak var lbRelease: UILabel!
    
    var btDismiss: UIBarButtonItem!
    private var listDevice: [DeviceInfo] = []
    var viewModel: RegisterDeviceVM!
    var typeRegisterDevice: RouteLogin = .app
    var isRemoveLoginScreen: Bool = false
    private let toMain: PublishSubject<TapRegisterScreen> = PublishSubject.init()
    private let deleteDevice: PublishSubject<DeviceInfo> = PublishSubject.init()
    private let registerDevice: PublishSubject<String> = PublishSubject.init()
    private var listDeviceUpdate: PublishSubject<[DeviceInfo]> = PublishSubject.init()
    private let autoMoveHome: PublishSubject<Bool> = PublishSubject.init()
    private var isInstall: Bool = false
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton = true
        self.navigationController?.isNavigationBarHidden = false

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
}
extension RegisterDeviceViewController {
    // MARK: - Funcs
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DetectCell.nib, forCellReuseIdentifier: DetectCell.identifider)
        tableView.register(ListdeviceCell.nib, forCellReuseIdentifier: ListdeviceCell.identifider)
        
        switch typeRegisterDevice {
        case .app, .tutorial:
            self.navigationController?.isNavigationBarHidden = true
        case .cloud:
            self.navigationController?.isNavigationBarHidden = false
        default:
            break
        }
                
        self.btDismiss = UIBarButtonItem(image: Asset.icBack.image, style: .plain, target: self, action: nil)
        shouldHiddenLeftButton(isHidden: true)
    }
    
    private func shouldHiddenLeftButton(isHidden: Bool) {
        switch typeRegisterDevice {
        case .menu, .cloudDraft, .cloudFolder, .cloudFolderSelection, .cloud, .detecStatusUser:
            self.navigationItem.leftBarButtonItem = isHidden ? nil : self.btDismiss
        default:
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    func bindViewModel() {
        let input = RegisterDeviceVM
            .Input(loadTrigger: self.rx.viewDidAppear.asDriver().mapToVoid(),
                   tapToMain: toMain.asDriverOnErrorJustComplete(),
                   deleteDevice: self.deleteDevice.asDriverOnErrorJustComplete(),
                   registerDevice: self.registerDevice.asDriverOnErrorJustComplete(),
                   isRemoveLoginScreen: self.rx.viewDidAppear.asDriver().mapToVoid(),
                   autoMoveHome: self.autoMoveHome.asDriverOnErrorJustComplete(),
                   dismissTrigger: self.btDismiss.rx.tap.asDriver()
            )
        let output = viewModel.transform(input)
        
        output.tapToMain
            .drive()
            .disposed(by: self.disposeBag)
        
        output.registerDevice
            .drive()
            .disposed(by: self.disposeBag)
        
        output.retryAction
            .drive()
            .disposed(by: self.disposeBag)
        
        output.retryActionName
            .drive()
            .disposed(by: self.disposeBag)
        
        output.getlistTheDevice
            .drive()
            .disposed(by: self.disposeBag)
        output.dismissTrigger.drive().disposed(by: disposeBag)
        
        output.listDevice
            .do { [weak self] (list) in
                guard let wSelf = self else {
                    return
                }
                wSelf.listDevice = list
                wSelf.listDeviceUpdate.onNext(wSelf.listDevice)
                
                if AppManager.shared.billingInfo.value.billingStatus == .free && wSelf.listDevice.count > GlobalConstant.limitDevice {
                    if wSelf.typeRegisterDevice == .menu {
                        wSelf.typeRegisterDevice = .detecStatusUser
                    }
                    wSelf.shouldHiddenLeftButton(isHidden: true)
                    wSelf.navigationItem.hidesBackButton = true
                    wSelf.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                } else {
                    wSelf.shouldHiddenLeftButton(isHidden: false)
                    wSelf.navigationItem.hidesBackButton = false
                    wSelf.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                }
                
                wSelf.view.layoutIfNeeded()
                wSelf.tableView.reloadData()
            }.drive().disposed(by: disposeBag)
        
        output.deviceName
            .do { [weak self] name in
                guard let wSelf = self else {
                    return
                }
                let index = IndexPath(row: 0, section: 0)
                guard let cell = wSelf.tableView.cellForRow(at: index) as? DetectCell else {
                    return
                }
                cell.lbModelName.text = name
                wSelf.tableView.reloadData()
            }
            .drive()
            .disposed(by: self.disposeBag)
        
        output.deleteDevice
            .withLatestFrom(self.deleteDevice.asDriverOnErrorJustComplete(), resultSelector: { ( _, item) -> DeviceInfo in
                return item
            })
            .do { [weak self] d in
                guard let wSelf = self else {
                    return
                }
                //                check The device has delete which is The Current Device
//                guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
//                    return
//                }
//                if d.id == deviceId {
//                    var userInfo = AppManager.shared.userInfo.value
//                    userInfo?.deviceStatus = .unregistered
//                    AppManager.shared.userInfo.accept(userInfo)
//                }
                wSelf.setupLayoutViewRelease(device: d)
//                wSelf.listDevice = wSelf.listDevice.filter { $0.id != d.id }
//                wSelf.listDeviceUpdate.onNext(wSelf.listDevice)
//                wSelf.tableView.reloadData()
                
            }.drive().disposed(by: disposeBag)
        
        Observable.combineLatest(self.listDeviceUpdate, output.deviceName.asObservable())
            .bind { [weak self] (list, name) in
                guard let wSelf = self else {
                    return
                }
                let check = list.first(where: { $0.name == name })
                let install: Bool = (check == nil) ? false : true
                wSelf.isInstall = install
                wSelf.tableView.reloadData()
                
                let isRegister = (AppManager.shared.userInfo.value?.deviceStatus == .registered) ? true : false
                
                if isRegister && list.count <= Constant.limitDevice && wSelf.typeRegisterDevice.isForceDetectDevices {
                    wSelf.autoMoveHome.onNext(true)
                } else {
                    wSelf.autoMoveHome.onNext(false)
                }
                
        }.disposed(by: disposeBag)
        
        output.err
            .drive()
            .disposed(by: self.disposeBag)
        
        output.errName
            .drive()
            .disposed(by: self.disposeBag)
        
        output.doErrService
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loading
            .do { loading in
                //hide icon loading
//                loading ?  GooLoadingViewController.shared.show() : GooLoadingViewController.shared.hide()
                
                //load api and don't allow user touch anymore
                self.view.isUserInteractionEnabled = !loading
            }
            .drive()
            .disposed(by: self.disposeBag)
        
        output.isRemoveLoginScreen
            .drive()
            .disposed(by: self.disposeBag)
        
        output.retrySession
            .drive()
            .disposed(by: self.disposeBag)
                
        output.getListDeviceAfterActionDelete
            .drive()
            .disposed(by: self.disposeBag)
        
        output.autoMoveHome
            .drive()
            .disposed(by: self.disposeBag)
        output.checkBillingStatus
            .drive()
            .disposed(by: self.disposeBag)
        output.errorHandlerBilling
            .drive()
            .disposed(by: self.disposeBag)
        
        tracking(output: output)
    }
    
    
    private func setupLayoutViewRelease(device: DeviceInfo) {
        let center = CGPoint(x: self.view.center.x, y: self.view.frame.height - 70)
        self.view.showToastLogin(message: "\(device.name) \(L10n.RegisterDevices.Alert.releaseDevice)",
                                 center: center,
                                 controlView: self.view)
    }
    private func tracking(output: RegisterDeviceVM.Output) {
        output.listDevice.asObservable().take(1).bind { (list) in
            GATracking.scene(.openRegisterDeviceScreen, params: [.deviceRegisterCount(list.count)])
        }.disposed(by: disposeBag)
        
        self.toMain.asObserver().bind { [weak self] (type) in
            guard let wSelf = self else {
                return
            }
            switch type {
            case .addDevice:
                var screenName = ""
                switch wSelf.typeRegisterDevice {
                case .app, .tutorial, .login, .cloud:
                    screenName = L10n.ScreenName.screenRegister
                default:
                    screenName = wSelf.typeRegisterDevice.screenName
                }
                GATracking.tap(.tapRegisterDevice, params: [.screenName(screenName)])
            default:
                break
            }
        }.disposed(by: disposeBag)
    }
    
}
extension RegisterDeviceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listDevice.count == 0 {
            return 1
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ListdeviceCell.identifider) as! ListdeviceCell
            let userInfo = AppManager.shared.userInfo.value
            cell.setupStackView(
                hasRegister: userInfo?.deviceStatus == DeviceStatus.registered ? true : false,
                list: self.listDevice,
                type: self.typeRegisterDevice
            )
            cell.removeDevice = { [weak self] d in
                guard let wSelf = self else {
                    return
                }
                wSelf.toMain.onNext(.removeDevice(d))
                wSelf.deleteDevice.onNext(d)
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: DetectCell.identifider) as! DetectCell
            let userInfo = AppManager.shared.userInfo.value
            cell.setupUI(hasRegister: userInfo?.deviceStatus == DeviceStatus.registered ? true : false ,
                         count: self.listDevice.count,
                         type: self.typeRegisterDevice)
            cell.addTextInstall(isInstall: self.isInstall, count: self.listDevice.count)
//            cell.setupLayout(count: self.listDevice.count, status: AppSettings.billingInfo?.billingStatus ?? .free)
            cell.moveToRegister = { [weak self]  in
                guard  let wSelf = self  else {
                    return
                }
                wSelf.toMain.onNext(.addDevice(cell.lbModelName.text ?? ""))
                wSelf.registerDevice.onNext(cell.lbModelName.text ?? "")
            }
            cell.moveToMain = { [weak self]  in
                guard  let wSelf = self  else {
                    return
                }
                wSelf.toMain.onNext(.ignore)
            }
            return cell
        }
    }
}
extension RegisterDeviceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
}

extension RegisterDeviceViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
            navigationController?.popViewController(animated: true)
        }
        return false
    }
}
