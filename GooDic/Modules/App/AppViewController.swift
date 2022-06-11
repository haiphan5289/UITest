//
//  AppViewController.swift
//  GooDic
//
//  Created by ttvu on 6/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// Fake Splash view controller
/// waiting for configuration and fetching data
class AppViewController: UIViewController, ViewBindableProtocol {

    // MARK: - Rx & Data
    let disposeBag = DisposeBag()
    var viewModel: AppViewModel!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // to make sure AppManager has been init
        let _ = AppManager.shared
    }
    
    // MARK: - Funcs
    func bindViewModel() {
        let input = AppViewModel.Input(loadTrigger: Driver.just(()))
        let output = viewModel.transform(input)
        
        output.forceUpdate
            .drive(onNext: { _ in
                GATracking.tap(.tapForcedUpdate)
            }).disposed(by: self.disposeBag)
        
        output.toMain
            .drive()
            .disposed(by: self.disposeBag)
        
        output.loading
            .drive(UIApplication.shared.rx.isNetworkActivityIndicatorVisible)
            .disposed(by: self.disposeBag)
        
        output.error
            .drive()
            .disposed(by: self.disposeBag)
        
        output.errorBillngStatus
            .drive()
            .disposed(by: self.disposeBag)
        
        output.errorListDevices
            .drive()
            .disposed(by: self.disposeBag)
        
        output.detectUserFree.drive().disposed(by: self.disposeBag)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
