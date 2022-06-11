//
//  SortVC.swift
//  GooDic
//
//  Created by haiphan on 09/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum ElementSort: String, Codable, CaseIterable {
    case title, updated_at, created_at, manual, free
    
    var text: String {
        switch self {
        case .created_at: return L10n.Sort.createDate
        case .title: return L10n.Sort.title
        case .updated_at: return L10n.Sort.updateDate
        case .manual: return L10n.Sort.manual
        case .free: return ""
        }
    }
    
    static func getElement(text: String) -> Self {
        if text == title.rawValue {
            return title
        }
        
        if text == updated_at.rawValue {
            return updated_at
        }
        
        if text == created_at.rawValue {
            return created_at
        }
        
        if text == manual.rawValue {
            return manual
        }
        
        return free
    }
}

class SortVC: BaseViewController, ViewBindableProtocol {
    


    @IBOutlet weak var btDismiss: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var viewModel: SortVM!
    private let updateSortEvent: PublishSubject<SortModel> = PublishSubject.init()
    private var openfromScreen: SortVM.openfromScreen = .folderLocal
    private var sortModel: SortModel?
    private let moveToPreniumEvent: PublishSubject<Void> = PublishSubject.init()
    private let dismissEvent: PublishSubject<Void> = PublishSubject.init()
    private var elementSorts: BehaviorRelay<[ElementSort]> = BehaviorRelay.init(value: [])
    private let updateRotationEvent: PublishSubject<CGSize> = PublishSubject.init()
    private var size: CGSize = UIScreen.main.bounds.size
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupRX()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationTitle(type: .sort)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { [unowned self] _ in
            self.tableView.setContentOffset(.zero, animated: true)
            self.updateRotationEvent.onNext(size)
            self.tableView.reloadData()
        }
    }
    
}
extension SortVC {
    
    private func setupUI() {
        self.tracking()
        
        tableView.register(SortCell.nib, forCellReuseIdentifier: SortCell.identifider)
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        
        self.view.addSeparator(at: .top, color: Asset.modelCellSeparator.color)
    }
    
    func bindViewModel() {
        
        let dismissEvent = Driver.merge(self.btDismiss.rx.tap.asDriverOnErrorJustComplete(),
                                        self.dismissEvent.asDriverOnErrorJustComplete())

        let input = SortVM
            .Input(dismissEvent: dismissEvent,
                   updateSortEvent: self.updateSortEvent.asDriverOnErrorJustComplete(),
                   moveToPreniumEvent: self.moveToPreniumEvent.asDriverOnErrorJustComplete(),
                   updateRotationEvent: self.updateRotationEvent.asDriverOnErrorJustComplete())

        let output = viewModel.transform(input)
        
        output.dismissEvent.drive(onNext: { [weak self] _ in
            guard let wSelf = self else { return }
            switch wSelf.openfromScreen {
            case .folderCloud: GATracking.tap(.tapCloudFolderSortOrderClose)
            case .folderLocal: GATracking.tap(.tapFolderSortOrderClose)
            case .draftsLocal: GATracking.tap(.tapDraftSortOrderClose)
            case .draftsCloud: GATracking.tap(.tapCloudDraftSortOrderClose)
            }
        }).disposed(by: disposeBag)
        
        output.updateSortEvent.drive().disposed(by: disposeBag)
        
        output.postSort.drive().disposed(by: disposeBag)
        
        output.getSortModel.drive { [weak self] sort in
            guard let wSelf = self else { return }
            wSelf.sortModel = sort
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)
        
        output.error.drive().disposed(by: disposeBag)
        
        output.openfromScreen.drive { [weak self] openfromScreen in
            guard let wSelf = self else { return }
            wSelf.openfromScreen = openfromScreen
            switch openfromScreen {
            case .folderCloud, .folderLocal: wSelf.elementSorts.accept(wSelf.valueFree())
            case .draftsLocal, .draftsCloud: wSelf.elementSorts.accept(wSelf.valueDraftsFree())
            }
        }.disposed(by: disposeBag)
        
        
        output.getBillingInfo.drive { [weak self] billing in
            guard let wSelf = self else { return }
            switch billing.billingStatus {
            case .paid:
                switch wSelf.openfromScreen{
                case .draftsLocal, .draftsCloud: wSelf.elementSorts.accept(wSelf.valueDraftsPaid())
                case .folderCloud, .folderLocal: wSelf.elementSorts.accept(wSelf.valuePaid())
                }
                
            case .free: break
            }
            
            wSelf.tableView.reloadData()
        }.disposed(by: self.disposeBag)

        output.moveToPreniumEvent.drive().disposed(by: disposeBag)
        
        output.updateRotationEvent.drive { [weak self] size in
            guard let wSelf = self else { return }
            wSelf.size = size
        }.disposed(by: self.disposeBag)
        
    }
    
    private func setupRX() {
        self.elementSorts.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: SortCell.identifider, cellType: SortCell.self)) { [weak self] (row, element, cell) in
                guard let wSelf = self else { return }
                cell.lbTitle.text = element.text
                if let sort = wSelf.sortModel {
                    cell.updateSort(element: element, sort: sort, openfromScreen: wSelf.openfromScreen)
                }
                cell.lineViewTop.isHidden = (row != 0) ? true : false
                cell.showPayView(element: element)
                cell.updateLayoutRotation(size: wSelf.size)
        }.disposed(by: disposeBag)
        
        self.tableView.rx.itemSelected.bind { [weak self] idx in
            guard let wSelf = self else { return }
            let item = wSelf.elementSorts.value[idx.row]
            switch item {
            case .free:
                wSelf.moveToPreniumEvent.onNext(())
                wSelf.addTapTracking(item: item)
            case .manual:
                if AppManager.shared.billingInfo.value.billingStatus == .free {
                    wSelf.moveToPreniumEvent.onNext(())
                    wSelf.addTapTracking(item: item)
                } else {
                    wSelf.updateSort(item: item)
                    wSelf.dismissEvent.onNext(())
                } 
            case .created_at, .title, .updated_at:
                wSelf.updateSort(item: item)
            }

        }.disposed(by: disposeBag)
        
        let getSize = Driver.just(UIScreen.main.bounds.size)
        let updateRotation = self.updateRotationEvent.asDriverOnErrorJustComplete()
        Driver.merge(getSize, updateRotation).drive { [weak self] size in
            guard let wSelf = self else { return }
            switch SortCoodinator.StatusRotation.getStatus(size: size) {
            case .ipad, .iphonePortrait:
                wSelf.tableView.isScrollEnabled = false
            case .iphoneLandscape:
                wSelf.tableView.isScrollEnabled = true
            }
        }.disposed(by: self.disposeBag)

    }
    
    private func valueDraftsPaid() -> [ElementSort] {
        return [.title, .updated_at, .manual]
    }
    
    private func valueDraftsFree() -> [ElementSort] {
        return [.title, .updated_at, .manual, .free]
    }
    
    private func valueFree() -> [ElementSort] {
        return [.title, .updated_at, .created_at, .manual, .free]
    }
    
    private func valuePaid() -> [ElementSort] {
        return [.title, .updated_at, .created_at, .manual]
    }
    
    private func addTapTracking(item: ElementSort) {
        switch item {
        case .free:
            switch self.openfromScreen {
            case .folderCloud: GATracking.tap(.tapViewPremiumInCloudFolderSortOrder)
            case .folderLocal: GATracking.tap(.tapViewPremiumInFolderSortOrder)
            case .draftsLocal: GATracking.tap(.tapViewPremiumInDraftSortOrder)
            case .draftsCloud: GATracking.tap(.tapViewPremiumInCloudDraftSortOrder)
            }
        case .manual:
            switch self.openfromScreen {
            case .folderCloud: GATracking.tap(.tapCloudFolderSortOrderManualFree)
            case .folderLocal: GATracking.tap(.tapFolderSortOrderManualFree)
            case .draftsLocal: GATracking.tap(.tapDraftSortOrderManualFree)
            case .draftsCloud: GATracking.tap(.tapCloudDraftSortOrderManualFree)
            }
        default: break
        }
    }
    
    private func updateSort(item: ElementSort) {
        var sortModel: SortModel!
        if let sort = self.sortModel,  item == sort.sortName {
            sortModel = SortModel(sortName: item, asc: !sort.asc, isActiveManual: true)
        } else {
            sortModel = SortModel(sortName: item, asc: false, isActiveManual: true)
        }
        self.sortModel = sortModel
        self.updateSortEvent.onNext(sortModel)
        self.tableView.reloadData()
        switch self.openfromScreen {
        case .folderCloud: self.tapTrackingCloud(type: item, sortModel: sortModel)
        case .folderLocal: self.tapTracking(type: item, sortModel: sortModel)
        case .draftsLocal: self.tapTrackingDraftLocal(type: item, sortModel: sortModel)
        case .draftsCloud: self.tapTrackingDraftCloud(type: item, sortModel: sortModel)
        }
    }
    
    private func tapTrackingDraftCloud(type: ElementSort, sortModel: SortModel) {
        switch type {
        case .title:
            GATracking.tap(.tapCloudDraftSortOrderTitle)
        case .created_at: break
        case .updated_at:
            GATracking.tap(.tapCloudDraftSortOrderUpdatedAt)
        case .manual:
            GATracking.tap(.tapCloudDraftSortOrderManual)
        case .free: break
        }
        GATracking.tap(.tapCloudDraftSortOrder,params: [.sortOrder(sortModel)])
    }
    
    private func tapTrackingDraftLocal(type: ElementSort, sortModel: SortModel) {
        switch type {
        case .title:
            GATracking.tap(.tapDraftSortOrderTitle)
        case .created_at: break
        case .updated_at:
            GATracking.tap(.tapDraftSortOrderUpdatedAt)
        case .manual:
            GATracking.tap(.tapDraftSortOrderManual)
        case .free: break
        }
        GATracking.tap(.tapDraftSortOrder,params: [.sortOrder(sortModel)])
    }
    
    private func tapTrackingCloud(type: ElementSort, sortModel: SortModel) {
        switch type {
        case .title:
            GATracking.tap(.tapCloudFolderSortOrderTitle)
        case .created_at:
            GATracking.tap(.tapCloudFolderSortOrderCreatedAt)
        case .updated_at:
            GATracking.tap(.tapCloudFolderSortOrderUpdateAt)
        case .manual:
            GATracking.tap(.tapCloudFolderSortOrderManual)
        case .free: break
        }
        GATracking.tap(.tapCloudFolderSortOrder,params: [.sortOrder(sortModel)])
    }
    
    private func tapTracking(type: ElementSort, sortModel: SortModel) {
        switch type {
        case .title:
            GATracking.tap(.tapFolderSortOrderTitle)
        case .created_at:
            GATracking.tap(.tapFolderSortOrderCreatedAt)
        case .updated_at:
            GATracking.tap(.tapFolderSortOrderUpdatedAt)
        case .manual:
            GATracking.tap(.tapFolderSortOrderManual)
        case .free: break
        }
        GATracking.tap(.tapFolderSortOrder,params: [.sortOrder(sortModel)])
    }
    
    private func tracking() {
        // Tracking Tap events
        GATracking.scene(sceneType)
    }
}
extension SortVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
}
