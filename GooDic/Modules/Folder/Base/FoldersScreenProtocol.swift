//
//  FoldersScreenProtocol.swift
//  GooDic
//
//  Created by ttvu on 1/21/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol FoldersScreenProtocol: UIViewController {
    var folderCount: BehaviorSubject<Int> { get }
    var didCreateFolder: PublishSubject<UpdateFolderResult> { get }
    var foldersEvent: BehaviorSubject<[CDFolder]> { get }
}
