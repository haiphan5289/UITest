//
//  ViewBindableProtocol.swift
//  GooDic
//
//  Created by ttvu on 10/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

import UIKit

protocol ViewBindableProtocol: class {
    associatedtype ViewModelProtocol
    
    var viewModel: ViewModelProtocol! { get set }
    
    func bindViewModel()
}

extension ViewBindableProtocol where Self: UIViewController {
    func bindViewModel(_ vm: Self.ViewModelProtocol) {
        viewModel = vm
        self.loadViewIfNeeded()
        bindViewModel()
    }
}
