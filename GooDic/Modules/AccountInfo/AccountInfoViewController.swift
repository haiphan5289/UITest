//
//  AccountInfoViewController.swift
//  GooDic
//
//  Created by Hao Nguyen on 6/1/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AccountInfoViewController: BaseViewController, ViewBindableProtocol {

    @IBOutlet weak var actionButton: BorderButton!
    @IBOutlet weak var subcriptionButton: UIButton!
    @IBOutlet weak var userNameLabel: UILabel!
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: AccountInfoViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindUI()
    }
    
    private func bindUI() {
        AppManager.shared.userInfo
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] userInfo in
                guard let userInfo = userInfo else {
                    self?.viewModel.navigator.pop()
                    return
                }
                self?.userNameLabel.text = userInfo.name
            })
            .disposed(by: self.disposeBag)
    }
    
    func bindViewModel() {
        let actionTrigger = actionButton.rx
            .tap
            .asDriver()
        let subcriptionTrigger = subcriptionButton.rx
            .tap
            .asDriver()
        let input = AccountInfoViewModel.Input(
            actionTrigger: actionTrigger,
            subcriptionTrigger: subcriptionTrigger)
        let output = viewModel.transform(input)
        output.logoutAccount.drive().disposed(by: disposeBag)
        output.subcriptionAction.drive().disposed(by: disposeBag)
        
        tracking()
    }
    
    private func tracking() {
        GATracking.scene(self.sceneType)
    }
}
