//
//  GooInject.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

@propertyWrapper
public struct GooInject<T: GooServiceProtocol> {
    var component: T
    
    public init() {
        self.component = GooServices.shared.resolve(T.self)
    }
    
    public var wrappedValue: T {
        get { return component }
        mutating set { component = newValue }
    }
}
