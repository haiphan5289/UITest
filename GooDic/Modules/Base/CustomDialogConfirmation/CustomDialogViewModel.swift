//
//  NamingViewModel.swift
//  GooDic
//
//  Created by ttvu on 10/6/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct CustomDialogViewModel {
    let navigator: CustomDialogNavigateProtocol
    let useCase: CustomDialogUseCaseProtocol
    
}

extension CustomDialogViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
    }
    
    struct Output {
        let loadTrigger: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        let loadTrigger = input.loadTrigger
        return Output(
            loadTrigger: loadTrigger
        )
    }
}
