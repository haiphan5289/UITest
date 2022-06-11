//
//  MultiSelectionViewProtocol.swift
//  GooDic
//
//  Created by ttvu on 12/17/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol MultiSelectionViewProtocol: UIViewController {
    var editMode: BehaviorSubject<Bool> { get }
    var selectOrDeselectAllItemsTrigger: PublishSubject<Void> { get }
    var binItemsTrigger: PublishSubject<Void> { get }
    var moveItemsTrigger: PublishSubject<Void> { get }
    var selectedItems: BehaviorSubject<[IndexPath]> { get }
    var backToNormalModelTrigger: PublishSubject<Void> { get }
    var selectionButtonTitle: PublishSubject<String> { get }
    var itemCount: BehaviorSubject<Int> { get }
    var showedSwipeDocumentTooltip: PublishSubject<Bool> { get }
    var eventSelectDraftOver: PublishSubject<Void> { get }
    var totalSelectDrafts: Int { get set }
    var hideButtonEventTrigger: PublishSubject<Bool> { get }
}
