//
//  GooidSDK+Rx.swift
//  GooDic
//
//  Created by ttvu on 12/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import GooidSDK

extension Notification.Name {
    static let gooIDLogout = Notification.Name("gooIDLogout")
    static let gooIDLogin = Notification.Name("gooIDLogin")
    static let gooIDRegister = Notification.Name("gooIDRegister")
}

public enum GooIDResult {
    case success
    case cancel
}

extension Reactive where Base: GooidSDK {
    func login(waitingAPIListDevice: BehaviorRelay<Bool>? = nil) -> Observable<GooIDResult> {
        return Observable.create { (observer) -> Disposable in
            if let rootVC = UIWindow.key?.rootViewController {
                var vc: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
                while vc?.presentedViewController != nil {
                    vc = vc?.presentedViewController
                }
                UIWindow.key?.backgroundColor = UIColor.black
                GooidSDK.sharedInstance.login(vc ?? rootVC, provider: .gooid) { (ticket, error) in
                    UIWindow.key?.backgroundColor = UIColor.white
                    if ticket != nil {
                        
                        observer.onNext(.success)
                        
                        NotificationCenter.default.post(name: .gooIDLogin, object: nil)
                        
                        observer.onCompleted()
                        
                        if let waitingAPIListDevice = waitingAPIListDevice {
                            while waitingAPIListDevice.value == false {
                                continue
                            }
                        }
                        
                    } else {
                        let err = GooidSDKError(error)
                        
                        if err.isCancel {
                            observer.onNext(.cancel)
                            observer.onCompleted()
                        } else {
                            observer.onError(error!)
                        }
                    }
                }
            } else {
                observer.onError(NSError())
            }
            
            return Disposables.create()
        }
    }
    
    func register() -> Observable<GooIDResult> {
        return Observable.create { (observer) -> Disposable in
            if let rootVC = UIWindow.key?.rootViewController {
                let vc = rootVC.presentedViewController ?? rootVC
                
                UIWindow.key?.backgroundColor = UIColor.black
                GooidSDK.sharedInstance.register(vc, provider: .mailaddress) { (ticket, error) in
                    UIWindow.key?.backgroundColor = UIColor.white
                    if ticket != nil {
                        observer.onNext(.success)
                        NotificationCenter.default.post(name: .gooIDRegister, object: nil)
                        observer.onCompleted()
                    } else {
                        let err = GooidSDKError(error)
                        
                        if err.isCancel {
                            observer.onNext(.cancel)
                            observer.onCompleted()
                        } else {
                            observer.onError(error!)
                        }
                    }
                }
            } else {
                observer.onError(NSError())
            }
            
            return Disposables.create()
        }
    }
    
    func refresh() -> Observable<GooIDResult> {
        return Observable.create { (observer) -> Disposable in
            GooidSDK.sharedInstance.refreshGooidTicket { (ticket, error) in
                if ticket != nil {
                    observer.onNext(.success)
                    observer.onCompleted()
                } else {
                    let err = GooidSDKError(error)
                    
                    if err.isCancel {
                        observer.onNext(.cancel)
                        observer.onCompleted()
                    } else {
                        observer.onError(error!)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func logout() -> Observable<Void> {
        return Observable.deferred { () -> Observable<Void> in
            GooidSDK.sharedInstance.logout()
            
            NotificationCenter.default.post(name: .gooIDLogout, object: nil)
            
            return Observable.just(())
        }
    }
}

