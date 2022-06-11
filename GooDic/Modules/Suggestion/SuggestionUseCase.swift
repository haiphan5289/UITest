//
//  SuggestionUseCase.swift
//  GooDic
//
//  Created by ttvu on 6/24/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

protocol SuggestionUseCaseProtocol {
    func getDetail(path: String) -> URL?
}

struct SuggestionUseCase: SuggestionUseCaseProtocol {
    
    @GooInject var service: DictionaryService
    
    func getDetail(path: String) -> URL? {
        return service.gateway.fetchDetail(path: path)
    }
}
