//
//  SuggestionSearchLocalGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public struct SuggestionSearchLocalGateway: SuggestionSearchGatewayProtocol {
    private let errorMessage =
    """
    {
        "status": "99",
        "error_message": "メッセージ"
    }
    """
    
    private let normalData =
    """
    {
      "status": "00",
      "count": 5,
      "word": "テスト",
      "data": [
        "テスト",
        "テストゥール",
        "テストエンジニア",
        "テストケース",
        "テストコース"
      ]
    }
    """
    
    private let emptyData =
    """
    {
      {
        "status": "00",
        "count": 0,
        "word": "テスト",
        "data": [
        ]
      }
    }
    """
    
    public init() {}
    
    public func fetch(text: String, dictType: SuggestionDictType, limit: Int) -> Observable<GooResponse<[String]>> {
        let data: Data
        if text == "Error" {
            data = errorMessage.data(using: .utf8)!
        }
        else if text == "Empty" {
            data = emptyData.data(using: .utf8)!
        }
        else {
            data = normalData.data(using: .utf8)!
        }
        
        return Observable.just(data)
            .map({ (data) in
                let result = try autoreleasepool(invoking: { () -> GooResponse<[String]> in
                    return try JSONDecoder().decode(GooResponse<[String]>.self, from: data)
                })
                return result
            })
    }
}
