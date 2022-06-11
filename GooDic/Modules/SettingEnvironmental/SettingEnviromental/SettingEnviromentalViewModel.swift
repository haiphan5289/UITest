//
//  SettingEnviromentalViewModel.swift
//  GooDic
//
//  Created by Vinh Nguyen on 20/04/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

struct SettingEnviromentalViewModel {
    var navigator: SettingEnviromentalNavigateProtocol
    var useCase: SettingEnviromentalUseCaseProtocol
    
    let rawData: [SettingEnviromentalData]
    
    init(data: [SettingEnviromentalData], useCase: SettingEnviromentalUseCaseProtocol, navigator: SettingEnviromentalNavigateProtocol) {
        self.rawData = data
        self.useCase = useCase
        self.navigator = navigator
    }
}

extension SettingEnviromentalViewModel: ViewModelProtocol {
    struct Input {
        let loadDataTrigger: Driver<Void>
        let selectCellTrigger: Driver<IndexPath>
        let eventShowAlertAutoSave: Driver<Void>
    }
    
    struct Output {
        let data: Driver<[SettingEnviromentalData]>
        let selectedCell: Driver<SettingEnviromentalAction>
        let eventShowAlertAutoSave: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let data = input.loadDataTrigger
            .map({getSettingEnviromentalData()})
            .asDriver()
                
        let selectedCell = input.selectCellTrigger
            .withLatestFrom(data) { ($0, $1) }
            .filter ({ (indexPath, items) -> Bool in
                indexPath.row < items.count && indexPath.row != 0
            })
            .map ({ (indexPath, items) -> SettingEnviromentalData in
                return items[indexPath.row]
            })
            .do(onNext: { (obj) in
                switch obj.action {
                case .openSettingBackup:
                    self.navigator.toSettingBackup()
                    break
                case .none:
                    break
            }})
            .map({ $0.action })
        
        let eventShowAlertAutoSave = input.eventShowAlertAutoSave
            .asObservable()
            .flatMap({ _ -> Driver<Void> in
                return self.navigator.showMessage(L10n.SettingFont.alertAutoSave).asDriverOnErrorJustComplete()
            })
            .asDriverOnErrorJustComplete()
        
        return Output(
            data: data,
            selectedCell: selectedCell,
            eventShowAlertAutoSave: eventShowAlertAutoSave
        )
    }
    
    private func getSettingEnviromentalData() -> [SettingEnviromentalData] {
        return rawData
    }
}
