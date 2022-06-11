//
//  DeviceRegistrationViewController.swift
//  GooDic
//
//  Created by ttvu on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ErrorDeviceRegistrationViewController: UIViewController, ViewBindableProtocol {

    // MARK: - UI
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var paddingTop: NSLayoutConstraint!
    
    // MARK: - Rx & Data
    var disposeBag = DisposeBag()
    var viewModel: ErrorDeviceRegistrationViewModel!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func bindViewModel() {
        let input = ErrorDeviceRegistrationViewModel.Input(
            deviceTrigger: registerButton.rx.tap.asDriver(),
            viewWillDisappear: self.rx.viewWillDisappear.asDriver().mapToVoid()
        )
        
        let output = viewModel.transform(input)
        
        output.openDeviceScreen
            .drive()
            .disposed(by: self.disposeBag)
    }
    
    func setPaddingTop(value: CGFloat = 20) {
        paddingTop.constant = value
        view.layoutSubviews()
    }
}
