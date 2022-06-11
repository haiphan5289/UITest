//
//  DictionaryUseCase.swift
//  GooDic
//
//  Created by ttvu on 5/29/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol DictionaryUseCaseProtocol {
    func search(text: String) -> Observable<URL>
    func suggest(text: String) -> Observable<[String]>
}

struct DictionaryUseCase: DictionaryUseCaseProtocol {
    
    @GooInject var dictService: DictionaryService
    @GooInject var suggestionService: SuggestionSearchService
    private let disposeBag = DisposeBag()
    func search(text: String) -> Observable<URL> {
        if let url = dictService.gateway.fetch(text: text, mode: .prefix) {
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
