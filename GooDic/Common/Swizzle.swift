//
//  Swizzle.swift
//  GooDic
//
//  Created by ttvu on 11/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

// https://github.com/MarioIannotta/SwizzleSwift/blob/master/Sources/SwizzleSwift/SwizzleSwift.swift
import Foundation

infix operator <->

public struct SwizzlePair {
    let original: Selector
    let swizzled: Selector
}

extension Selector {
    
    public static func <->(original: Selector, swizzled: Selector) -> SwizzlePair {
        SwizzlePair(original: original, swizzled: swizzled)
    }
    
}

public struct Swizzle {

    @_functionBuilder
    public struct SwizzleFunctionBuilder {
        
        public static func buildBlock(_ swizzlePairs: SwizzlePair...) -> [SwizzlePair] {
            Array(swizzlePairs)
        }
        
    }
    
    @discardableResult
    public init(_ type: AnyObject.Type, @SwizzleFunctionBuilder _ makeSwizzlePairs: () -> [SwizzlePair]) {
        let swizzlePairs = makeSwizzlePairs()
        swizzle(type: type, pairs: swizzlePairs)
    }
    
    @discardableResult
    public init(_ type: AnyObject.Type, @SwizzleFunctionBuilder _ makeSwizzlePairs: () -> SwizzlePair) {
        let swizzlePairs = makeSwizzlePairs()
        swizzle(type: type, pairs: [swizzlePairs])
    }
    
    private func swizzle(type: AnyObject.Type, pairs: [SwizzlePair]) {
        pairs.forEach { swizzlePair in
             guard
                 let originalMethod = class_getInstanceMethod(type, swizzlePair.original),
                 let swizzledMethod = class_getInstanceMethod(type, swizzlePair.swizzled)
                 else { return }
             method_exchangeImplementations(originalMethod, swizzledMethod)
         }
    }
    
}
