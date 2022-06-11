//
//  DrawPresentVM.swift
//  GooDic
//
//  Created by haiphan on 13/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct DrawPresentVM {
    var navigator: DrawPresentNavigateProtocol
    var useCase: DrawPresentUseCaseProtocol
    var openfromScreen: SortVM.openfromScreen
    let sortModel: SortModel
    let folder: Folder?
}

extension DrawPresentVM: ViewModelProtocol {
    struct Input {
        let loadEvent: Driver<Void>
        let tapDismiss: Driver<Void>
    }
    
    struct Output {
        let loadEvent: Driver<Void>
        let tapDismiss: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let loadEvent = input.loadEvent.do { _ in
            self.navigator.toSort(openfromScreen: self.openfromScreen, sortModel: self.sortModel, folder: self.folder)
        }
        
        let tapDismiss = input.tapDismiss
            .do { _ in
                self.navigator.dismissDraw()
            }
        
        
        return Output(
            loadEvent: loadEvent,
            tapDismiss: tapDismiss
        )
    }
}
