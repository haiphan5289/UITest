//
//  RankingSearchLocalGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public struct RankingSearchLocalGateway: RankingSearchGatewayProtocol {
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
        "update_date": "5/10",
        "data": [
            {
                "rank": "1",
                "word": "口説く",
                "url": "/word/%E5%8F%A3%E8%AA%AC%E3%81%8F/"
            },
            {
                "rank": "2",
                "word": "自粛",
                "url": "/word/%E8%87%AA%E7%B2%9B/"
            },
            {
                "rank": "3",
                "word": "ソーシャルディスタンス",
                "url": "/word/%E3%82%BD%E3%83%BC%E3%82%B7%E3%83%A3%E3%83%AB%E3%83%87%E3%82%A3%E3%82%B9%E3%82%BF%E3%83%B3%E3%82%B9/"
            },
            {
                "rank": "4",
                "word": "元の木阿弥",
                "url": "/word/%E5%85%83%E3%81%AE%E6%9C%A8%E9%98%BF%E5%BC%A5/"
            },
            {
                "rank": "5",
                "word": "目途",
                "url": "/word/%E7%9B%AE%E9%80%94/"
            },
            {
                "rank": "6",
                "word": "逸れる",
                "url": "/word/%E9%80%B8%E3%82%8C%E3%82%8B_%28%E3%81%AF%E3%81%90%E3%82%8C%E3%82%8B%29/"
            },
            {
                "rank": "7",
                "word": "目くじら",
                "url": "/word/%E7%9B%AE%E3%81%8F%E3%81%98%E3%82%89/"
            },
            {
                "rank": "8",
                "word": "食む",
                "url": "/word/%E9%A3%9F%E3%82%80/"
            },
            {
                "rank": "9",
                "word": "健啖",
                "url": "/word/%E5%81%A5%E5%95%96/"
            },
            {
                "rank": "10",
                "word": "葦の髄から天井を覗く",
                "url": "/word/%E8%91%A6%E3%81%AE%E9%AB%84%E3%81%8B%E3%82%89%E5%A4%A9%E4%BA%95%E3%82%92%E8%A6%97%E3%81%8F/"
            }
        ]
    }
    """
    
    private let emptyData =
    """
    {
        "status": "00",
        "update_date": "5/10",
        "data": [
        ]
    }
    """
    
    public init() {}
    
    public func fetch(text: String) -> Observable<GooResponse<[RankingWordData]>> {
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
                let result = try autoreleasepool(invoking: { () -> GooResponse<[RankingWordData]> in
                    return try JSONDecoder().decode(GooResponse<[RankingWordData]>.self, from: data)
                })
                return result
            })
    }
}
