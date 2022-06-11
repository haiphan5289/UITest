//
//  BackUpSettingVC.swift
//  GooDic
//
//  Created by haiphan on 21/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BackUpSettingVC: BaseViewController, ViewBindableProtocol {
    
    enum Action {
        case dismiss, share, moveToFont, moveToBackUp
    }

    @IBOutlet weak var btDismiss: UIBarButtonItem!
    @IBOutlet weak var btShare: UIButton!
    @IBOutlet weak var btMoveToFont: UIButton!
    @IBOutlet weak var lbBackUp: UILabel!
    @IBOutlet weak var imgPremium: UIImageView!
    @IBOutlet weak var btPremium: BorderButton!
    @IBOutlet weak var btMoveToBackUp: UIButton!
    @IBOutlet weak var lbNameSettingFont: UILabel!
    var viewModel: BackUpSettingVM!
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationTitle(type: .backUpSetting)
    }
    
    deinit {
        print("==== deinit BackUpSettingVC")
    }
}
extension BackUpSettingVC {
    
    private func setupUI() {
    }
    
    func bindViewModel() {
        
        let dismiss = self.btDismiss.rx.tap.map { Action.dismiss }
        let share = self.btShare.rx.tap.map { Action.share }
        let moveToFont = self.btMoveToFont.rx.tap.map { Action.moveToFont }
        let moveToBackUp = self.btMoveToBackUp.rx.tap.map { Action.moveToBackUp }
        
        let action = Observable.merge(dismiss, share, moveToFont, moveToBackUp).asDriverOnErrorJustComplete()
        
        let input = BackUpSettingVM
            .Input(actionEvent: action)
        
        let output = viewModel.transform(input)
        
        output.actionEvent.drive().disposed(by: self.disposeBag)
        
        output.getUserInfo.drive { [weak self] billingInfo in
            guard let wSelf = self else { return }
            switch billingInfo.billingStatus {
            case .paid:
                wSelf.lbBackUp.textColor = Asset.textPrimary.color
                wSelf.btPremium.borderColor = Asset.cc3333.color
                wSelf.btPremium.setTitleColor(Asset.cc3333.color, for: .normal)
                wSelf.imgPremium.isHidden = true
            case .free:
                wSelf.lbBackUp.textColor = Asset.cecece717171.color
                wSelf.btPremium.borderColor = Asset.cecece717171.color
                wSelf.btPremium.setTitleColor(Asset.cecece717171.color, for: .normal)
                wSelf.imgPremium.isHidden = false
            }
        }.disposed(by: self.disposeBag)

        output.getSettingFont.drive { [weak self] setting in
            guard let wSelf = self else { return }
            wSelf.lbNameSettingFont.text = setting.getTextValue()
        }.disposed(by: self.disposeBag)
        
        output.doApiBackUpCheck.drive().disposed(by: self.disposeBag)
        
        output.errorTracker.drive().disposed(by: self.disposeBag)


    }
    
    private func setupRX() {
        
    }
    
}
