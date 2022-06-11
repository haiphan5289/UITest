//
//  SettingViewController.swift
//  GooDic
//
//  Created by paxcreation on 5/19/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UITestCheck {
    static var shared = UITestCheck()
    var sizeZFont: String = ""
}

class SettingViewController: BaseViewController, ViewBindableProtocol {
    
    enum StateCell: Int, CaseIterable {
        case autoSave, fontSize, font, share
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btDismiss: UIBarButtonItem!
    
    private let updateSettingFont: PublishSubject<SettingFont> = PublishSubject.init()
    private let actionShare: PublishSubject<Void> = PublishSubject.init()
    private var listStatusCell = StateCell.allCases
    private let eventShowAlertAutoSave: PublishSubject<Void> = PublishSubject.init()
    var viewModel: SettingViewModel!
    
    private var settingFont: SettingFont?
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationTitle(type: .settingFont)
    }
    
}
extension SettingViewController {
    // MARK: - Funcs
    private func setupUI() {
        //        tracking()
        tableView.register(SettingCell.nib, forCellReuseIdentifier: SettingCell.identifider)
        tableView.delegate = self
        tableView.rowHeight = 50
        
        self.listStatusCell.remove(at: StateCell.autoSave.rawValue)
        self.view.addSeparator(at: .top, color: Asset.modelCellSeparator.color)
    }
    func bindViewModel() {
        
        let input = SettingViewModel
            .Input(updateSettingFont: self.updateSettingFont.asDriverOnErrorJustComplete(),
                   dismissTrigger: self.btDismiss.rx.tap.asDriver(),
                   actionShareTrigger: self.actionShare.asDriverOnErrorJustComplete(),
                   eventShowAlertAutoSave: self.eventShowAlertAutoSave.asDriverOnErrorJustComplete()
            )
        
        let output = viewModel.transform(input)
        
        output.updateSettingFont.drive().disposed(by: disposeBag)
        
        output.settingFont.drive { [weak self] setting in
            guard let wSelf = self else { return }
            wSelf.settingFont = setting
            wSelf.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        output.dismissTrigger.drive().disposed(by: disposeBag)
        
        output.actionShareTrigger.drive().disposed(by: disposeBag)
        
        output.detectOnCloud.map { [weak self] onCloud -> [StateCell] in
            guard let wSelf = self else { return  StateCell.allCases }
            if onCloud {
                if let index = wSelf.listStatusCell.firstIndex(where: { $0 == StateCell.share }) {
                    wSelf.listStatusCell.remove(at: index)
                }
                wSelf.btDismiss.image = Asset.icBack.image
            }
            return wSelf.listStatusCell
        }.asObservable().bind(to: tableView.rx.items(cellIdentifier: SettingCell.identifider, cellType: SettingCell.self)) { [weak self] (row, element, cell) in
            guard let wSelf = self else { return }
            if let s = wSelf.settingFont {
                cell.updateUI(state: element, settingFont: s)
            }
            UITestCheck.shared.sizeZFont = cell.lbValueFont.text ?? ""
            print("======== updateSettingFont \(UITestCheck.shared.sizeZFont)")
            cell.updateSettingFont = { [weak self] s in
                guard let wSelf = self else { return }
                wSelf.updateSettingFont.onNext(s)
                wSelf.settingFont = s
                
                wSelf.tableView.reloadData()
            }
            
            cell.actionShare = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.actionShare.onNext(())
            }
            
            cell.showAlertAutoSave = { [weak self] isOn in
                guard let wSelf = self else { return }
                if isOn {
                    wSelf.eventShowAlertAutoSave.onNext(())
                }
                let paramOn = isOn ? 0 : 1
                GATracking.tap(.tapSettingSave, params: [.save(paramOn)])
            }
        }.disposed(by: disposeBag)
        
        output.eventShowAlertAutoSave.drive().disposed(by: disposeBag)
        
        
    }
    private func tracking() {
        // Tracking Tap events
        GATracking.scene(sceneType)
    }
    
    private func updateLayoutIPad() {
//        switch UIDevice.current.userInterfaceIdiom {
//        case .pad:
//            let size = self.view.bounds
//            let isLandscape = (size.height < size.width) ? true : false
//            self.leftViewContent.constant = (isLandscape) ? Constant.spacing : 0
//            self.rightViewContent.constant = (isLandscape) ? Constant.spacing : 0
//        default:
//            break
//        }
    }
}
extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
}
