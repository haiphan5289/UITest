//
//  ThesaurusLocalGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public struct ThesaurusLocalGateway: ThesaurusGatewayProtocol {
    
    private let textError = "\nError"
    private let errorMessage =
    """
        {
            "status": "99",
            "error_message": "メッセージ"
        }
    """
    
    private let textNormal = ""
    private let normalData =
    """
    {
      "status": "00",
      "data": [
        {
          "target": "便利",
          "list": [
            "簡便",
            "重宝"
          ],
          "url": "/thsrs/9148/meaning/m0u/%E4%BE%BF%E5%88%A9/"
        },
        {
          "target": "日用品",
          "list": [
            "小間物",
            "荒物",
            "雑貨"
          ],
          "url": "/thsrs/6506/meaning/m0u/%E6%97%A5%E7%94%A8%E5%93%81/"
        },
        {
          "target": "必要",
          "list": [
            "必須",
            "所要",
            "入り用"
          ],
          "url": "/thsrs/15639/meaning/m0u/%E5%BF%85%E8%A6%81/"
        },
        {
          "target": "買い物",
          "list": [
            "買い出し",
            "買い付け"
          ],
          "url": "/thsrs/8067/meaning/m0u/%E8%B2%B7%E3%81%84%E7%89%A9/"
        }
      ]
    }
    """
    
    // "A AB A " -> "A AB A "
    private let textIndex = "\nA AB A AAA"
    private let indexData =
    """
    {
        "status": "00",
        "data": [
            {
                "target": "",
                "list": [
                    "A "
                ],
                "index": 1,
                "url": "/thsrs/9148/meaning/m0u/A/"
            },
            {
                "target": "A",
                "list": [
                    "A "
                ],
                "index": 3,
                "url": "/thsrs/9148/meaning/m0u/A/"
            },
            {
                "target": "A",
                "list": [
                    "A "
                ],
                "index": 2,
                "url": "/thsrs/9148/meaning/m0u/A/"
            },
            {
                "target": "A",
                "list": [
                    "A "
                ],
                "index": 5,
                "url": "/thsrs/9148/meaning/m0u/A/"
            },
            {
                "target": "A",
                "list": [
                    "A "
                ],
                "index": 15,
                "url": "/thsrs/9148/meaning/m0u/A/"
            }
        ]
    }
    """
    
    private let textEmpty = "\nEmpty"
    private let emptyData =
    """
    {
      "status": "00",
      "data": [
      ]
    }
    """
    
    public init() {}
    
    public func fetch(text: String) -> Observable<GooResponse<[ThesaurusData]>> {
        let data: Data
        if text == textError {
            data = errorMessage.data(using: .utf8)!
        }
        else if text == textEmpty {
            data = emptyData.data(using: .utf8)!
        }
        else if text == textIndex {
            data = indexData.data(using: .utf8)!
        }
        else {
            data = normalData.data(using: .utf8)!
        }
        
        return Observable.just(data)
            .map({ (data) in
                let result = try autoreleasepool(invoking: { () -> GooResponse<[ThesaurusData]> in
                    return try JSONDecoder().decode(GooResponse<[ThesaurusData]>.self, from: data)
                })
                return result
            })
    }
}
