//
//  ThesaurusService.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public protocol ThesaurusGatewayProtocol {
    func fetch(text: String) -> Observable<GooResponse<[ThesaurusData]>>
    func normalize(text: String) -> String
}

extension ThesaurusGatewayProtocol {
    public func normalize(text: String) -> String {
        var result = text
        
        result = result.replacingOccurrences(of: "/", with: "%2f")
        result = result.replacingOccurrences(of: "+", with: "%2f")
        result = result.replacingOccurrences(of: "&", with: "%2f")
        result = result.replacingOccurrences(of: "?", with: "%2f")
        
        return result
    }
}

public typealias ThesaurusService = GooService<ThesaurusGatewayProtocol>
