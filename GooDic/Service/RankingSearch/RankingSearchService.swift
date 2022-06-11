//
//  RankingSearchService.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public protocol RankingSearchGatewayProtocol {
    func fetch(text: String) -> Observable<GooResponse<[RankingWordData]>>
    func normalize(text: String) -> String
}

extension RankingSearchGatewayProtocol {
    public func normalize(text: String) -> String {
        var result = text
        
        result = result.replacingOccurrences(of: " ", with: ".")
        
        return result
    }
}

public typealias RankingSearchService = GooService<RankingSearchGatewayProtocol>
