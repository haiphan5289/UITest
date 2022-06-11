//
//  CustomDialogViewController.swift
//  GooDic
//
//  Created by paxcreation on 6/7/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CustomDialogViewController: UIViewController, ViewBindableProtocol {

    @IBOutlet weak var btOk: BorderButton!
    @IBOutlet weak var btLink: UIButton!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var lbSubTitle: UILabel!
    
    // MARK: - Rx + Data
    let disposeBag = DisposeBag()
    var viewModel: CustomDialogViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}
extension CustomDialogViewController {
    
    private func setupUI() {
        lbTitle.textColor = Asset.textPrimary.color
        lbSubTitle.textColor = Asset.textPrimary.color
    }
    
    func bindViewModel() {
        
        self.btLink.rx.tap.bind { _ in
            
            if let url = URL(string: GlobalConstant.notificationURL) {
                UIApplication.shared.open(url,
                                          options: [:] , completionHandler: nil)
            }
            
        }.disposed(by: disposeBag)
        
        self.btOk.rx.tap.bind { _ in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        let input = CustomDialogViewModel.Input(
            loadTrigger: Driver.just(()))
        
        let output = viewModel.transform(input)
        
        output.loadTrigger
            .drive()
            .disposed(by: self.disposeBag)
    }
    
}
