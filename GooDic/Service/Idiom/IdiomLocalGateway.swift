//
//  IdiomLocalGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public struct IdiomLocalGateway: IdiomGatewayProtocol {
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
      "data": [
        {
          "target": "のべつくま無し",
          "correct": "のべつ幕無し",
          "URL": "/word/%E3%81%AE%E3%81%B9%E3%81%A4%E5%B9%95%E7%84%A1%E3%81%97/"
        },
        {
          "target": "白羽の矢を当てた",
          "correct": "白羽の矢が立つ",
          "URL": "/word/%E7%99%BD%E7%BE%BD%E3%81%AE%E7%9F%A2%E3%81%8C%E7%AB%8B%E3%81%A4/"
        },
        {
          "target": "白羽の矢を当てた",
          "correct": "白羽の矢が立つ long text 白羽の矢が立つ",
          "URL": "/word/%E7%99%BD%E7%BE%BD%E3%81%AE%E7%9F%A2%E3%81%8C%E7%AB%8B%E3%81%A4/"
        },
        {
          "target": "白羽の矢を当てた toooo long text 白羽の矢を当てた白羽の矢を当てた白羽の矢を当てた白羽の矢を当てた白羽の矢を当てた白羽の矢を当てた白羽の矢を当てた白羽の矢を当てた",
          "correct": "白羽の矢が立つ toooo long text 白羽の矢が立つ白羽の矢が立つ 白羽の矢が立つ 白羽の矢が立つ白羽の矢が立つ",
          "URL": "/word/%E7%99%BD%E7%BE%BD%E3%81%AE%E7%9F%A2%E3%81%8C%E7%AB%8B%E3%81%A4/"
        },
        {
          "target": "のべつくま無し",
          "correct": "のべつ幕無し",
          "URL": "/word/%E3%81%AE%E3%81%B9%E3%81%A4%E5%B9%95%E7%84%A1%E3%81%97/"
        },
        {
          "target": "白羽の矢を当てた",
          "correct": "白羽の矢が立つ",
          "URL": "/word/%E7%99%BD%E7%BE%BD%E3%81%AE%E7%9F%A2%E3%81%8C%E7%AB%8B%E3%81%A4/"
        }
      ]
    }
    """
    
    private let emptyData =
    """
    {
      "status": "00",
      "data": [
      ]
    }
    """
    
    public init() {}
    
    public func fetch(text: String) -> Observable<GooResponse<[IdiomData]>> {
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
                let result = try autoreleasepool(invoking: { () -> GooResponse<[IdiomData]> in
                    return try JSONDecoder().decode(GooResponse<[IdiomData]>.self, from: data)
                })
                return result
            })
    }
}
