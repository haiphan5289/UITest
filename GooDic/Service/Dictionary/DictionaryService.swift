//
//  DictionaryService.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public enum DictionaryMode: String {
    case prefix = "m0u"
    case exact = "m1u"
    case backward = "m2u"
    case matchIncludeDescription = "m3u"
    case matchInHeading = "m6u"
}

public protocol DictionaryGatewayProtocol {
    func fetch(text: String, mode: DictionaryMode) -> URL?
    func fetchDetail(path: String) -> URL?
    func normalize(text: String) -> String
}

extension DictionaryGatewayProtocol {
    public func normalize(text: String) -> String {
        let list = text.components(separatedBy: .newlines)
        var result = list.first ?? ""
        result = result.trimmingCharacters(in: .whitespaces)
        
        let maximumChars: Int = 100
        return String(result.prefix(maximumChars))
    }
}

public typealias DictionaryService = GooService<DictionaryGatewayProtocol>
