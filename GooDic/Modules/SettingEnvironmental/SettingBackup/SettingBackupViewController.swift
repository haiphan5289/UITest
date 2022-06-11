//
//  SettingBackupViewController.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingBackupViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let heightOfBackupTitleCell: CGFloat = 40.0
        static let heightOfBackupMinuteCell: CGFloat = 50.0
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: SettingBackupViewModel!
    private let disposeBag = DisposeBag()
    private let eventShowAlertEnableBackup: PublishSubject<Void> = PublishSubject.init()
    private let eventUpdateSettingBackup: PublishSubject<SettingBackupModel> = PublishSubject.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
        // Do any additional setup after loading the view.
    }
    
}

extension SettingBackupViewController {
    
    private func setupUI() {
        self.setupTableView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SettingBackupViewCell.nib, forCellReuseIdentifier: SettingBackupViewCell.identifider)
        
        tableView.register(SettingBackupTitleViewCell.nib, forCellReuseIdentifier: SettingBackupTitleViewCell.identifider)
        
        tableView.register(SettingBackupMinuteViewCell.nib, forCellReuseIdentifier: SettingBackupMinuteViewCell.identifider)
        
        tableView.separatorStyle = .none
    }
    
    func bindViewModel() {
        
        let input = SettingBackupViewModel
            .Input(loadDataTrigger: Driver.just(()),
                   selectCellTrigger: tableView.rx.itemSelected.asDriver(),
                   eventShowAlertEnableBackup: self.eventShowAlertEnableBackup.asDriverOnErrorJustComplete(),
                   updateSettingBackupTrigger: self.eventUpdateSettingBackup.asDriverOnErrorJustComplete())
        
        let output = viewModel.transform(input)
        
        output.data
            .drive(onNext: {[weak self] settingBackupModel in
                guard let wSelf = self, let settingBackupModel = settingBackupModel else {
                    return
                }
                AppSettings.settingBackupModel = settingBackupModel
                wSelf.tableView.reloadData()
            })
            .disposed(by: self.disposeBag)
        
        output.eventShowAlertEnableBackup.drive().disposed(by: disposeBag)
        output.error.drive().disposed(by: disposeBag)
        output.updateSettingBackup.drive(onNext: {[weak self] settingBackupModel in
            guard let wSelf = self else {
                return
            }
            AppSettings.settingBackupModel = settingBackupModel
            wSelf.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        tracking(output: output)
    }
    
    private func setupRX() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath) in
                guard let wSelf = self else {
                    return
                }
                wSelf.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func tracking(output: SettingBackupViewModel.Output) {
        // track scene
        GATracking.scene(self.sceneType)
        
        // track tap events
        output.selectedCell
            .drive(onNext: { (action) in
                switch action {
                case .isSelectMinute:
                    return
                default:
                    return
                }
            })
            .disposed(by: self.disposeBag)
    }
}

extension SettingBackupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == SettingBackUpSectionCell.settingBackupTitle.rawValue {
            return Constant.heightOfBackupTitleCell
        } else if indexPath.section == SettingBackUpSectionCell.settingBackupMinute.rawValue {
            return Constant.heightOfBackupMinuteCell
        } else {
            return UITableView.automaticDimension
        }
    }
    
}

extension SettingBackupViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(at: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == SettingBackUpSectionCell.settingBackupData.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingBackupViewCell.identifider, for: indexPath) as! SettingBackupViewCell
            
            if let item = viewModel.item(atIndexPath: indexPath) {
                cell.bind(data: item)
                cell.updateCellWithStatusBackup()
                
                cell.actionSwitch = { [weak self] (settingBackupModel) in
                    guard let wSelf = self else { return }
                    wSelf.eventUpdateSettingBackup.onNext(settingBackupModel)
                }

                cell.showAlertEnableBackup = { [weak self] (isOn) in
                    guard let wSelf = self else { return }
                    if isOn {
                        wSelf.eventShowAlertEnableBackup.onNext(())
                    }
                }
            }
            
            cell.setHiddenLineBottomView(isHidden: true)
            return cell
        } else if indexPath.section == SettingBackUpSectionCell.settingBackupTitle.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingBackupTitleViewCell.identifider, for: indexPath) as! SettingBackupTitleViewCell
            
            if let item = viewModel.item(atIndexPath: indexPath) {
                cell.bind(data: item)
                cell.updateCellWithBilling()
            }
            
            return cell
        } else if indexPath.section == SettingBackUpSectionCell.settingBackupRule.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingBackupViewCell.identifider, for: indexPath) as! SettingBackupViewCell
            
            if let item = viewModel.item(atIndexPath: indexPath) {
                cell.bind(data: item)
                cell.updateCellWithBilling()
                cell.actionSwitch = { [weak self] (settingBackupModel) in
                    guard let wSelf = self else { return }
                    wSelf.eventUpdateSettingBackup.onNext(settingBackupModel)
                }
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingBackupMinuteViewCell.identifider, for: indexPath) as! SettingBackupMinuteViewCell
            
            if let item = viewModel.item(atIndexPath: indexPath) {
                cell.bind(data: item)
                cell.updateCellWithBilling()
            }
            
            return cell
        }
    }
}
