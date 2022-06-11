//
//  AgreementViewModel.swift
//  GooDic
//
//  Created by ttvu on 6/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct AgreementData {
    let date: Date
    let url: URL
}

struct AgreementViewModel {
    let navigator: AgreementNavigateProtocol
    let useCase: AgreementUseCaseProtocol
    let agreementData: AgreementData
    
    init(data: AgreementData, useCase: AgreementUseCaseProtocol, navigator: AgreementNavigateProtocol) {
        self.agreementData = data
        self.useCase = useCase
        self.navigator = navigator
    }
}

extension AgreementViewModel: ViewModelProtocol {
    struct Input {
        let loadTrigger: Driver<Void>
        let finishLoadTrigger: Driver<Void>
        let agreeTrigger: Driver<Void>
        let disagreeTrigger: Driver<Void>
        let clickURLTrigger: Driver<URL>
    }
    
    struct Output {
        let finishedLoad: Driver<Bool>
        let clickedURL: Driver<Void>
        let agreed: Driver<Void>
        let disagreed: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
        
        let checkReAgreement = input.loadTrigger
            .do(onNext: { (_) in
                if self.useCase.isFirstRun() == false {
//                    self.navigator.toNotifyNewAgreementAlert()
                    self.navigator.moveCustomDialog()
                }
            })
            .map({ false })
        
        let finishedLoad = Driver.merge(
            checkReAgreement,
            input.finishLoadTrigger.map({ true })
        )
        
        let clickedURL = input.clickURLTrigger
            .do(onNext: { url in
                if let data = self.useCase.isApplicationPrivacyPolicyURL(url) {
                    self.navigator.toWebView(url: url, cachePolicy: data.cachePolicy, title: data.title, sceneType: data.sceneType)
                } else {
                    self.navigator.toExternalWebView(url: url)
                }
            })
            .mapToVoid()
        
        let agreed = input.agreeTrigger
            .do(onNext: { self.useCase.setAgreementDate(self.agreementData.date) })
            .map(self.useCase.isFirstRun)
            .do(onNext: { (isFirstRun) in
                if isFirstRun {
                    self.navigator.toTutorial()
                } else {
                    self.navigator.toMainView()
                }
            })
            .mapToVoid()
        
        let disagreed = input.disagreeTrigger
            .flatMap({ self.navigator.toDisagreeAlert().asDriverOnErrorJustComplete() })
            .filter({ $0 })
            .mapToVoid()
            .do(onNext: self.navigator.quit)
        
        return Output(
            finishedLoad: finishedLoad,
            clickedURL: clickedURL,
            agreed: agreed,
            disagreed: disagreed
        )
    }
}
