//
//  ThesaurusGooGateway.swift
//  GooDic
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public struct ThesaurusGooGateway: ThesaurusGatewayProtocol {
    
    let session: URLSession
    
    public init() {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
    }
    
    public func fetch(text: String) -> Observable<GooResponse<[ThesaurusData]>> {
        guard let url = buildURLComponents()?.url else {
            return Observable.error(GooServiceError.badURL)
        }

        let newText = normalize(text: text)
        let params = "sentence="+newText
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(GlobalConstant.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = params.data(using: .utf8)
        
        return session.rx
            .data(request: request)
            .map({ (data) in
                let result = try autoreleasepool(invoking: { () -> GooResponse<[ThesaurusData]> in
                    return try JSONDecoder().decode(GooResponse<[ThesaurusData]>.self, from: data)
                })
                return result
            })
    }
    
    private func buildURLComponents() -> URLComponents? {
        guard let urlComponents = URLComponents(string: "\(Environment.apiScheme + Environment.apiHost + Environment.apiThsrsPath)") else { return nil }
    
        return urlComponents
    }
}
