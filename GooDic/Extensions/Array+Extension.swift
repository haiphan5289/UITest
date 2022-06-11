//
//  Array+Extension.swift
//  GooDic
//
//  Created by Hao Nguyen on 7/16/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit

extension Array {
    /// Splits the receiving array into multiple arrays
    ///
    /// - Parameter subCollectionCount: The number of output arrays the receiver should be divided into
    /// - Returns: An array containing `subCollectionCount` arrays. These arrays will be filled round robin style from the receiving array.
    ///            So if the receiver was `[0, 1, 2, 3, 4, 5, 6]` the output would be `[[0, 3, 6], [1, 4], [2, 5]]`. If the reviever is empty the output
    ///            Will still be `subCollectionCount` arrays, they just all will be empty. This way it's always safe to subscript into the output.
    func split(subCollectionCount: Int) -> [[Element]] {
        precondition(subCollectionCount > 1, "Can't split the array unless you ask for > 1")
        var output: [[Element]] = []

        (0..<subCollectionCount).forEach { (outputIndex) in
            let indexesToKeep = stride(from: outputIndex, to: count, by: subCollectionCount)
            let subCollection = enumerated().filter({ indexesToKeep.contains($0.offset)}).map({ $0.element })
            output.append(subCollection)
        }

        precondition(output.count == subCollectionCount)
        return output
    }
}
