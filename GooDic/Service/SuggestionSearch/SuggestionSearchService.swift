//
//  SuggestionSearchService.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public enum SuggestionDictType: String {
    case all = "all" // all
    case engJapan = "ej" // english-japanese
}

public protocol SuggestionSearchGatewayProtocol {
    func fetch(text: String, dictType: SuggestionDictType, limit: Int) -> Observable<GooResponse<[String]>>
    func normalize(text: String) -> String
}

extension SuggestionSearchGatewayProtocol {
    
    private func buildURLComponents() -> URLComponents? {
        guard let urlComponents = URLComponents(string: "\("https://dictapp.goo.ne.jp/api/v1/suggest/")") else { return nil }
        
        return urlComponents
    }
    
    public func normalize(text: String) -> String {
        let result = text.components(separatedBy: .whitespacesAndNewlines)
        
        return result.joined(separator: "_")
    }
}

public typealias SuggestionSearchService = GooService<SuggestionSearchGatewayProtocol>
