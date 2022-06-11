//
//  TutorialViewController.swift
//  GooDic
//
//  Created by ttvu on 6/1/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TutorialViewController: BaseViewController, ViewBindableProtocol {
    
    // MARK: - UI
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: - Rx + Data
    var disposeBag = DisposeBag()
    var viewModel: TutorialViewModel!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupAccessibility()
    }
    
    // MARK: - Funcs
    private func setupAccessibility() {
        self.nextButton.accessibilityLabel = "next"
    }
    
    func bindViewModel() {
        let input = TutorialViewModel.Input(
            loadData: Driver.just(()),
            nextTrigger: nextButton.rx.tap.asDriver()
        )
        
        let output = viewModel.transform(input)
        
        output.loaded
            .drive()
            .disposed(by: self.disposeBag)
        
        output.toMainFlow
            .drive()
            .disposed(by: self.disposeBag)
        
        output.toPurchaseFlow
            .drive()
            .disposed(by: self.disposeBag)
        
        tracking()
    }
    
    private func tracking() {
        GATracking.scene(self.sceneType)
    }
}
