//
//  AppManager.swift
//  GooDic
//
//  Created by ttvu on 11/27/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GooidSDK
import Network

/// uses to save all data accessed from anywhere in-app
class AppManager {
    
    struct Constant {
        static let decimalValueSetting: Character = ","
        static let folderIdDraftHome: String = "all"
        static let folderIdDraftUncategorized: String = ""
    }
    
    // singleton
    static let shared = AppManager()
    
    let disposeBag = DisposeBag()
    
      
    var hasRegister: Bool = false
    // to notify that the application has checked the user to be a new user or old user
    let checkedNewUser = BehaviorSubject(value: false)
    
    // current user info, nil: haven't logged in yet
    let userInfo = BehaviorRelay<UserInfo?>(value: AppSettings.userInfo)
    
    // current billing info, nil: haven't logged in yet
    let billingInfo = BehaviorRelay<BillingInfo>(value: BillingInfo(platform: "", billingStatus: .free))
    let detectListDevice: PublishSubject<[DeviceInfo]> = PublishSubject.init()
    let detectFinalListDevice: PublishSubject<[DeviceInfo]> = PublishSubject.init()
    
    let eventUpdateSearch: PublishSubject<SettingSearch> = PublishSubject.init()
    let eventUpdateSearchSetting: PublishSubject<SettingSearch> = PublishSubject.init()
    var billingText: FileStoreBillingText?
    
    let reachability: Reachability
    private let monitor = NWPathMonitor()
    var isConnected = true
    let eventShouldAddStorePayment = BehaviorSubject(value: false)
    var folders: [CDFolder] = []
    let detectBodyDraftGreaterThan100: Int = 100
    init() {
        reachability = try! Reachability()
        registerGooIDObserver()
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
        monitor.pathUpdateHandler = { path in
            if path.status == .unsatisfied {
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isConnected = true
                }
            }
        }
        
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
}
 
// MARK: - UserInfo
extension AppManager {
    func registerGooIDObserver() {
        let login = NotificationCenter.default.rx
            .notification(.gooIDLogin)
        
        let register = NotificationCenter.default.rx
            .notification(.gooIDRegister)
        
        Observable.merge(login, register)
            .bind(onNext: { _ in self.updateUserInfoIfNeeded() })
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.gooIDLogout)
            .bind(onNext: { _ in self.userInfo.accept(nil) })
            .disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx
            .notification(.IAPHelperShouldAddStorePayment)
            .bind(onNext: { notifi in
                if let isShow = notifi.object as? Bool {
                    self.eventShouldAddStorePayment.onNext(isShow)
                }
            })
            .disposed(by: self.disposeBag)
        
        self.userInfo
            .asObservable()
            .skip(1)
            .bind(onNext: { [weak self] value in
                AppSettings.userInfo = value
                if value == nil {
                    self?.billingInfo.accept(BillingInfo(platform: "", billingStatus: .free))
                }
            })
            .disposed(by: self.disposeBag)
        
        self.billingInfo
            .asObservable()
            .skip(1)
            .bind(onNext: { value in
                AppSettings.billingInfo = value
                if var userInfo = AppManager.shared.userInfo.value {
                    userInfo.billingStatus = value.billingStatus
                    AppManager.shared.userInfo.accept(userInfo)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    func updateUserInfoIfNeeded(_ errorTracker: ErrorTracker? =  nil) {
        if GooidSDK.sharedInstance.isLoggedIn {
            if let cache = AppSettings.userInfo, cache.name.isEmpty == false {
                // get data from local
                self.userInfo.accept(cache)
            } else {
                // fetch user name and registered devices
                let userName: Observable<String>
                    
                if let errorTracker = errorTracker {
                    userName = getUserName()
                        .trackError(errorTracker)
                } else {
                    userName = getUserName()
                }
                
                let userNameFlow = userName
                    .catchError({ (error) -> Observable<String> in
                        if let error = error as? GooServiceError {
                            switch error {
                            case .maintenanceCannotUpdate(let name):
                                if let name = name as? String {
                                    return Observable.just(name)
                                }
                            default:
                                break
                            }
                        }
                        
                        return Observable.just("")
                    })
                    .asDriverOnErrorJustComplete()
                
                Driver.combineLatest(
                    userNameFlow,
                    getRegisteredDeviceStatus().asDriver(onErrorJustReturn: .unknown),
                    getBillingInfoStatus().asDriver(onErrorJustReturn: BillingInfo(platform: "", billingStatus: .free)),
                    resultSelector: { (userName, status, billingStatus) -> UserInfo in
                        self.billingInfo.accept(billingStatus)
                        self.updateSettingSearch(billingStatus: billingStatus)
                        return UserInfo(name: userName, deviceStatus: status, billingStatus: billingStatus.billingStatus)
                    })
                    .drive(onNext: { self.userInfo.accept($0) })
                    .disposed(by: self.disposeBag)
            }
        }
    }
    
    func updateRegisteredDeviceStatus(_ errorTracker: ErrorTracker? =  nil) {
        let deviceStatus: Observable<DeviceStatus>
            
        if let errorTracker = errorTracker {
            deviceStatus = getRegisteredDeviceStatus()
                .trackError(errorTracker)
        } else {
            deviceStatus = getRegisteredDeviceStatus()
        }
        
        return deviceStatus
            .withLatestFrom(self.userInfo.asObservable(), resultSelector: { (newValue, userInfo) -> UserInfo? in
                if var userInfo = userInfo {
                    userInfo.deviceStatus = newValue
                    return userInfo
                }
                
                return UserInfo(name: "", deviceStatus: newValue, billingStatus: .free)
            })
            .bind(onNext: { self.userInfo.accept($0) })
            .disposed(by: self.disposeBag)
    }
    
    private func getUserName() -> Observable<String> {
        CurrentCloudService().cloudService.gateway
            .getAccountInfo()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
    }
    
    private func getRegisteredDeviceStatus() -> Observable<DeviceStatus> {
        CurrentCloudService().cloudService.gateway
            .getRegisteredDevices()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .catchError({ (error) -> Observable<[DeviceInfo]> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenanceCannotUpdate(let data):
                        if let list = data as? [DeviceInfo] {
                            return Observable.just(list)
                        }
                    default:
                        break
                    }
                }
                
                return Observable.error(error)
            })
            .map({ list -> DeviceStatus in
                guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
                    return .unknown
                }
                
                return list.first(where: { $0.id == deviceID }) != nil ? .registered : .unregistered
            })
    }
    
    private func getBillingInfoStatus() -> Observable<BillingInfo> {
        CurrentCloudService().cloudService.gateway
            .getBillingStatus()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .catchError({ (error) -> Observable<GooResponseBillingInfo> in
                if let error = error as? GooServiceError {
                    switch error {
                    case .maintenanceCannotUpdate(let data):
                        if let responseBillingInfo = data as? GooResponseBillingInfo {
                            return Observable.just(responseBillingInfo)
                        }
                    default:
                        break
                    }
                }
                
                return Observable.error(error)
            })
            .map({ responseBillingInfo -> BillingInfo in
                return BillingInfo(platform: responseBillingInfo.platform, billingStatus: responseBillingInfo.billingStatus)
            })
    }
    
    func detectListDeviceWeb(errTrack: ErrorTracker) {
        var loadFirst: Bool = true
        var errServer: Bool = false
        self.detectListDevice.asObservable().bind { list in
            
            if self.billingInfo.value.billingStatus == .free {
                if let index = list.firstIndex(where: { $0.name.uppercased().contains(GlobalConstant.nameDevicePC) }),
                   !errServer {
                    let device = list[index]
                    self.deleteDevice(deviceId: device.id, errTrack: errTrack) { err in
                        errServer = err
                        self.getListDevice(errTrack: errTrack)
                    }
                } else {
                    self.detectFinalListDevice.onNext(list)
                }
            } else {
                self.detectFinalListDevice.onNext(list)
            }
            
        }.disposed(by: disposeBag)
        
        if loadFirst {
            self.getListDevice(errTrack: errTrack)
            loadFirst = false
        }
    }
    
    func deleteDevice(deviceId: String, errTrack: ErrorTracker, completion: @escaping (Bool) -> Void) {
        CurrentCloudService().cloudService.gateway
            .deleteDevice(deviceId: deviceId)
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .catchError({ (error) -> Observable<Void> in
                completion(true)
                return Observable.error(error)
            })
            .trackError(errTrack)
            .bind { list in
                completion(false)
            }.disposed(by: disposeBag)
    }
    
    private func getListDevice(errTrack: ErrorTracker) {
        CurrentCloudService().cloudService.gateway
            .getRegisteredDevices()
            .timeout(.seconds(GlobalConstant.requestTimeout), scheduler: MainScheduler.instance)
            .retry(GlobalConstant.requestRetry, shouldRetry: { ($0 is GooServiceError) == false })
            .trackError(errTrack)
            .bind { list in
                self.detectListDevice.onNext(list)
            }.disposed(by: disposeBag)
    }
    
    func updateSearchUserPaidAfterLogin(login: Bool) {
        AppSettings.settingSearch = SettingSearch(isSearch: !login, isReplace: login, billingStatus: .free)
        self.eventUpdateSearch.onNext(SettingSearch(isSearch: !login, isReplace: login, billingStatus: .free))
    }
    
    func updateSettingSearch(billingStatus: BillingInfo) {
        if AppSettings.settingSearch?.billingStatus == billingStatus.billingStatus {
            return
        }
        
        switch billingStatus.billingStatus {
        case .free:
            AppSettings.settingSearch = SettingSearch(isSearch: true, isReplace: false, billingStatus: .free)
        case .paid:
            AppSettings.settingSearch = SettingSearch(isSearch: false, isReplace: true, billingStatus: .paid)
            self.eventUpdateSearchSetting.onNext(SettingSearch(isSearch: false, isReplace: true, billingStatus: .paid))
        }
    }
    
    func getCurrentVersionApp() -> String? {
        return Bundle.main.applicationVersion
    }
    
    func detectSortModel(value: String, isActiveManual: Bool) -> SortModel {
        if let idx = value.firstIndex(of: Constant.decimalValueSetting) {
            let pos = value.distance(from: value.startIndex, to: idx)
            let start = value.index(value.startIndex, offsetBy: 0)
            let end = value.index(value.startIndex, offsetBy: pos)
            let range = start..<end
            let sortName = String(value[range])
            let elementSort = ElementSort.getElement(text: sortName)
            var isAsc: Bool = false
            
            //distance pos to the first characters to 1 includes: "pos"
            if value.count > pos + 1 {
                let startAsc = value.index(value.startIndex, offsetBy: pos + 1)
                let endAsc = value.index(value.startIndex, offsetBy: value.count)
                let rangeAsc = startAsc..<endAsc
                let asc = String(value[rangeAsc])
                if asc == "asc" {
                    isAsc = true
                }
            }
            return SortModel(sortName: elementSort, asc: isAsc, isActiveManual: isActiveManual)
            
        } else {
            return SortModel.valueDefault
        }
    }

    func getHeightSafeArea(type: GetHeightSafeArea.SafeAreaType) -> CGFloat {
        return GetHeightSafeArea.shared.getHeight(type: type)
    }

    func getCurrentScene() -> GATracking.Scene {
        guard let currentVC = self.getCurrentViewController() else {
            return GATracking.Scene.unknown
        }
        
        if currentVC.isKind(of: HomeViewController.self) {
            return GATracking.Scene.openHomeScreen
        }
        
        if currentVC.isKind(of:MenuViewController.self) {
            return GATracking.Scene.menu
        }
        
        if currentVC.isKind(of: FolderBrowserViewController.self) {
            return GATracking.Scene.folder
        }
        
        if currentVC.isKind(of: DictionaryViewController.self) {
            return GATracking.Scene.search
        }
        
        if currentVC.isKind(of: CreationViewController.self) {
            return GATracking.Scene.create
        }
        
        if currentVC.isKind(of: TrashViewController.self) {
            return GATracking.Scene.trash
        }

        return GATracking.Scene.unknown
    }
    
    func getCurrentViewController() -> UIViewController? {
        return UIApplication.getTopViewController()
    }
    
    func imageSort(sortModel: SortModel) -> UIImage? {
        switch  sortModel.sortName {
        case .created_at:
            let img = (sortModel.asc) ? Asset.imgCreatedateAscending.image : Asset.imgCreatedateDescending.image
            return img
        case .updated_at:
            let img = (sortModel.asc) ? Asset.imgUpdatedateAscending.image : Asset.imgUpdatedateDescending.image
            return img
        case .title:
            let img = (sortModel.asc) ? Asset.imgTittleAscending.image : Asset.imgTittleDescending.image
            return img
        case .manual:
            let img = (sortModel.isActiveManual ?? false) ? Asset.icSortDone.image : Asset.imgSortManual.image
            return img
        case .free: return nil
        }
    }
    
    func getFolderId(folder: Folder?) -> String {
        if let folderId = folder?.id.cloudID {
            return folderId
        } else {
            return Constant.folderIdDraftHome
        }
    }
}

struct CurrentCloudService {
    @GooInject var cloudService: CloudService
}
