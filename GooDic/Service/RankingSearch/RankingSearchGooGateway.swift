//
//  RankingSearchGooGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public struct RankingSearchGooGateway: RankingSearchGatewayProtocol {
    
    let session: URLSession
    
    public init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    }
    
    public func fetch(text: String) -> Observable<GooResponse<[RankingWordData]>> {
        guard var url = buildURLComponents()?.url else {
            return Observable.error(GooServiceError.badURL)
        }
        
        let txt = normalize(text: text)
        url.appendPathComponent(txt)
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(GlobalConstant.userAgent, forHTTPHeaderField: "User-Agent")
        
        return session.rx
            .data(request: request)
            .map({ (data) in
                let result = try autoreleasepool(invoking: { () -> GooResponse<[RankingWordData]> in
                    return try JSONDecoder().decode(GooResponse<[RankingWordData]>.self, from: data)
                })
                return result
            })
    }
    
    private func buildURLComponents() -> URLComponents? {
        guard let urlComponents = URLComponents(string: "\("https://dictapp.goo.ne.jp/api/v1/ranking/")") else { return nil }
        
        return urlComponents
    }
}
