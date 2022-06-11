//
//  GooDataProtocol.swift
//  GooDic
//
//  Created by ttvu on 8/28/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

protocol GooDataProtocol {
    var id: UUID { get }
    var target: String { get }
    var index: Int { get }
    var list: [String] { get }
}

extension GooDataProtocol {
    var order: Int { self.index }
}
