//
//  AdvancedDictionaryUseCase.swift
//  GooDic
//
//  Created by haiphan on 10/11/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

protocol AdvancedDictionaryUseCaseProtocol {
    func notifyDictionary() -> Observable<NotiWebModel?>
    func search(text: String, type: DictionaryMode) -> Observable<URL>
    func suggest(text: String) -> Observable<[String]>
}

struct AdvancedDictionaryUseCase: AdvancedDictionaryUseCaseProtocol, AuthenticationUseCaseProtocol {
    
    @GooInject var remoteConfigService: RemoteConfigService
    @GooInject var dictService: DictionaryService
    @GooInject var suggestionService: SuggestionSearchService
    private let disposeBag = DisposeBag()
        
    func notifyDictionary() -> Observable<NotiWebModel?> {
        return remoteConfigService.gateway.notifyDictionary()
    }

    func search(text: String, type: DictionaryMode) -> Observable<URL> {
        if let url = dictService.gateway.fetch(text: text, mode: type) {
            return Observable.just(url)
        } else {
            return Observable.empty()
        }
    }
    func suggest(text: String) -> Observable<[String]> {
        guard let urlComponents = URLComponents(string: "\(Environment.apiScheme + Environment.apiHost + Environment.apiSuggestPath)"),
              var url = urlComponents.url  else {
            return Observable.empty()
        }
        let txt = self.normalize(text: text)
        url.appendPathComponent(SuggestionDictType.all.rawValue)
        url.appendPathComponent(txt)
        url.appendPathComponent("\(10)")
        return Observable.create { (observe) -> Disposable in
            GooAPIRouter.requestAPI(ofType: [String].self, url: url, parameters: nil, method: .post)
                .subscribe(onNext: { (result) in
                    switch result.result {
                    case .error(let error):
                        observe.onError(error)
                    case .empty:
                        return observe.onNext([])
                    case .normal(let list):
                        return observe.onNext(list)
                    }
                }, onError: { (err) in
                    observe.onError(err)
                })
                .disposed(by: disposeBag)
            return Disposables.create()
        }
    }
    
    func normalize(text: String) -> String {
        let result = text.components(separatedBy: .whitespacesAndNewlines)
        
        return result.joined(separator: "_")
    }
}
