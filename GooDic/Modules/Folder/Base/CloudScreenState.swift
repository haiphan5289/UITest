//
//  CloudScreenState.swift
//  GooDic
//
//  Created by ttvu on 1/8/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

enum CloudScreenState {
    case errorNetwork
    case notRegisterDevice
    case notLoggedIn
    case hasData
    case empty
    case none
}

protocol CloudScreenViewProtocol: UIViewController {
    // to update title after fetching data if needed
    var hasChangedTitle: PublishSubject<String> { get }
    var state: BehaviorSubject<CloudScreenState> { get }
}
