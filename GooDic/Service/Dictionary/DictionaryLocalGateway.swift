//
//  DictionaryLocalGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

public struct DictionaryLocalGateway: DictionaryGatewayProtocol {
    
    public init() {}
    
    public func fetch(text: String, mode: DictionaryMode) -> URL? {
        let searchedText = normalize(text: text)
        if searchedText.isEmpty {
            return nil
        }
        
        return buildURL(text: searchedText, mode: mode)
    }
    
    public func fetchDetail(path: String) -> URL? {
        guard var urlComponents = URLComponents(string: "https://www.google.com") else { return nil }
        
        urlComponents.path = path
        
        return urlComponents.url
    }
    
    private func buildURL(text: String, mode: DictionaryMode) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "www.google.com"
        urlComponents.path = "/search"
        
        let sentenceItem = URLQueryItem(name: "q", value: text)
        urlComponents.queryItems = [sentenceItem]
        
        return urlComponents.url
    }
}
