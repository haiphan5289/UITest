//
//  SettingSearchViewController.swift
//  GooDic
//
//  Created by paxcreation on 5/20/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingSearchViewController: BaseViewController, ViewBindableProtocol {

    enum StateCell: Int, CaseIterable {
        case search, replace, pay
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btDismiss: UIButton!
    
    private let updateSettingSearch: PublishSubject<SettingSearch> = PublishSubject.init()
    private let movePremium: PublishSubject<Void> = PublishSubject.init()
    private let actionShare: PublishSubject<Void> = PublishSubject.init()
    private let dataSource: BehaviorRelay<[Int]> = BehaviorRelay.init(value: [StateCell.search.rawValue,
                                                                              StateCell.replace.rawValue,
                                                                              StateCell.pay.rawValue])
    
    private var settingSearch: SettingSearch?
    private var currentIndex: IndexPath?
    
    private let disposeBag = DisposeBag()
    var viewModel: SettingSearchVM!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavigationTitle(type: .settingSearch)
    }
    
}
extension SettingSearchViewController {
    // MARK: - Funcs
    private func setupUI() {
//        tracking()
        self.tableView.register(SettingSearchCell.nib, forCellReuseIdentifier: SettingSearchCell.identifider)
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableView.automaticDimension
        
    }
    func bindViewModel() {
        self.dataSource.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: SettingSearchCell.identifider, cellType: SettingSearchCell.self)) { [weak self] (row, element, cell) in
                guard let wSelf = self,
                      let stateCell = StateCell(rawValue: element) else { return }

                if let s = wSelf.settingSearch {
                    cell.updateUI(state: stateCell, setting: s)
                }

//                cell.actionShare = {
//                    self.actionShare.onNext(())
//                }
//
        }.disposed(by: disposeBag)
    
        self.tableView.rx.itemSelected
            .withLatestFrom(self.dataSource.asObservable(), resultSelector: { (index, list) -> (IndexPath, [Int]) in
                return (index, list)
            })
            .bind { [weak self] item in
                let element = item.1[item.0.row]
            guard let wSelf = self,
                  let s = wSelf.settingSearch,
                  let tap = StateCell(rawValue: element) else { return }
            switch tap {
            case .search:
                let settingTemp = SettingSearch(isSearch: true, isReplace: false, billingStatus: s.billingStatus)
                wSelf.updateSettingSearch.onNext(settingTemp)
            case .replace:
                if AppSettings.settingSearch?.billingStatus == .free {
                    wSelf.movePremium.onNext(())
                } else {
                    GATracking.tap(.tapFindAndReplace)
                    let settingTemp = SettingSearch(isSearch: false, isReplace: true, billingStatus: s.billingStatus)
                    wSelf.updateSettingSearch.onNext(settingTemp)
                }

            case .pay:
                let userStatus: GATracking.UserStatus = AppManager.shared.userInfo.value == nil
                    ? .other
                    : .regular
                GATracking.tap(.tapViewPremium, params: [.userStatus(userStatus)])
                wSelf.movePremium.onNext(())
            }
        }.disposed(by: disposeBag)

        let input = SettingSearchVM
            .Input(tapTrigger: Driver.just(()),
                   updateSettingSearch: self.updateSettingSearch.asDriverOnErrorJustComplete(),
                   dismissTrigger: self.btDismiss.rx.tap.asDriver(),
                   movePremium: self.movePremium.asDriverOnErrorJustComplete()
                   )

        let output = viewModel.transform(input)
        
        output.tapTrigger.drive().disposed(by: disposeBag)
        
        output.settingSearch.drive { [weak self] setting in
            guard let wSelf = self else { return }
            wSelf.settingSearch = setting
            if setting.billingStatus.rawValue == BillingStatus.paid.rawValue {
                wSelf.dataSource.accept([StateCell.search.rawValue,
                                         StateCell.replace.rawValue,])
            }
            wSelf.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        output.dismissTrigger.drive().disposed(by: disposeBag)
        
        output.movePremium.drive().disposed(by: disposeBag)
//
//        output.actionShareTrigger.drive().disposed(by: disposeBag)
        

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
extension SettingSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
}
