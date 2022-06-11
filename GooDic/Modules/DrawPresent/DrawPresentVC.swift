//
//  DrawPresentVC.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DrawPresentVC: BaseViewController, ViewBindableProtocol {

    @IBOutlet weak var contentView: UIView!
    private let tap: UITapGestureRecognizer = UITapGestureRecognizer()
    var viewModel: DrawPresentVM!
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
}
extension DrawPresentVC {
    
    private func setupUI() {
        self.contentView.addGestureRecognizer(tap)
    }
    
    func bindViewModel() {
        
        let input = DrawPresentVM
            .Input(loadEvent: self.rx.viewWillAppear.mapToVoid().asDriverOnErrorJustComplete(),
                   tapDismiss: self.tap.rx.event.mapToVoid().asDriverOnErrorJustComplete())
        
        let output = viewModel.transform(input)
        
        output.loadEvent.drive().disposed(by: disposeBag)
        
        output.tapDismiss.drive().disposed(by: disposeBag)

    }
    
    private func setupRX() {
        
    }
}
