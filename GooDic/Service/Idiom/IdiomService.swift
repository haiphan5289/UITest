//
//  IdiomService.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public protocol IdiomGatewayProtocol {
    func fetch(text: String) -> Observable<GooResponse<[IdiomData]>>
    func normalize(text: String) -> String
}

extension IdiomGatewayProtocol {
    public func normalize(text: String) -> String {
        var result = text
        
        result = result.replacingOccurrences(of: "/", with: "%2f")
        result = result.replacingOccurrences(of: "+", with: "%2f")
        result = result.replacingOccurrences(of: "&", with: "%2f")
        result = result.replacingOccurrences(of: "?", with: "%2f")
        
        return result
    }
}

public typealias IdiomService = GooService<IdiomGatewayProtocol>
