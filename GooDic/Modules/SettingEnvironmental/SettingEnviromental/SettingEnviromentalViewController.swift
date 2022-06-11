//
//  SettingEnviromentalViewController.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingEnviromentalViewController: BaseViewController, ViewBindableProtocol {
    
    struct Constant {
        static let heightOfBackupCell: CGFloat = 55.0
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: SettingEnviromentalViewModel!
    private let disposeBag = DisposeBag()
    private var data = [SettingEnviromentalData]()
    private let eventShowAlertAutoSave: PublishSubject<Void> = PublishSubject.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
    }
}


extension SettingEnviromentalViewController {
    
    private func setupUI() {
        self.setupTableView()
    }
    
    private func setupTableView() {

        tableView.register(SettingAutoCloudSaveViewCell.nib, forCellReuseIdentifier: SettingAutoCloudSaveViewCell.identifider)
        tableView.register(SettingEnviromentalViewCell.nib, forCellReuseIdentifier: SettingEnviromentalViewCell.identifider)
        tableView.separatorStyle = .none
    }
    
    func bindViewModel() {
        
        let input = SettingEnviromentalViewModel
            .Input(loadDataTrigger: Driver.just(()),
                   selectCellTrigger: tableView.rx.itemSelected.asDriver(),
                   eventShowAlertAutoSave: self.eventShowAlertAutoSave.asDriverOnErrorJustComplete())
        
        let output = viewModel.transform(input)
        
//        output.data
//            .drive(onNext: {[weak self] data in
//                guard let wSelf = self else {
//                    return
//                }
//                wSelf.data
//            })
//            .disposed(by: self.disposeBag)
        
        output.data.drive(tableView.rx.items){(tv, row, model) -> UITableViewCell in
            
            if model.sceneType == .unknown {
                let cell = tv.dequeueReusableCell(withIdentifier: SettingAutoCloudSaveViewCell.identifider, for: IndexPath.init(row: 0, section: 0)) as! SettingAutoCloudSaveViewCell
                cell.bind(data: model)
                cell.showAlertAutoSave = { [weak self] isOn in
                    guard let wSelf = self else { return }
                    if isOn {
                        wSelf.eventShowAlertAutoSave.onNext(())
                    }
                    let paramOn = isOn ? 0 : 1
                    GATracking.tap(.tapSettingSave, params: [.save(paramOn)])
                }
                return cell
            } else {
                let cell = tv.dequeueReusableCell(withIdentifier: SettingEnviromentalViewCell.identifider, for: IndexPath.init(row: row, section: 0)) as! SettingEnviromentalViewCell
                cell.bind(data: model)
                return cell
            }

        }.disposed(by: disposeBag)
        
        output.eventShowAlertAutoSave.drive().disposed(by: disposeBag)
        
        tracking(output: output)
    }
    
    private func setupRX() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] (indexPath) in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: self.disposeBag)
        
        tableView
            .rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func tracking(output: SettingEnviromentalViewModel.Output) {
        // track scene
        GATracking.scene(self.sceneType)
        
        // track tap events
        output.selectedCell
            .drive(onNext: { (action) in
                switch action {
                case .openSettingBackup:
                    return
                default:
                    return
                }
            })
            .disposed(by: self.disposeBag)
    }
}

extension SettingEnviromentalViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return UITableView.automaticDimension
        }
        return Constant.heightOfBackupCell
        
    }
}
