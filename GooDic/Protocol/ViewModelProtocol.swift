//
//  ViewModelProtocol.swift
//  GooDic
//
//  Created by ttvu on 10/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input) -> Output
}
