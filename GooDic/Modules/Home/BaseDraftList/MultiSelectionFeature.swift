//
//  MultiSelectionFeature.swift
//  GooDic
//
//  Created by ttvu on 10/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum MultiSelectionType {
    case selectAll(Int)
    case unselectAll
    case normal
}

struct MultiSelectionInput {
    
    struct Constant {
        static let limitSelection: Int = 20
    }
    
    let title: Driver<String>
    let editingModeTrigger: Driver<Bool>
    let selectOrDeselectAllDraftsTrigger: Driver<Void>
    let selectOrDeselectInEditMode: Driver<IndexPath>
    let draftsCount: Driver<Int>
    let reset: Driver<Void>
}

struct MultiSelectionOutput {
    let title: Driver<String>
    let updateSelectedType: Driver<MultiSelectionType>
    let selectedDrafts: Driver<[IndexPath]>
}

protocol MultiSelectionFeature {
    func transform(_ input: MultiSelectionInput) -> MultiSelectionOutput
}

extension MultiSelectionFeature {
    func transform(_ input: MultiSelectionInput) -> MultiSelectionOutput {
        let selectedDrafts = BehaviorSubject<[IndexPath]>(value: [])
        var tapSelectionAll: Bool = false
        
        let resetSelectedDrafts = Driver
            .merge(
                input.editingModeTrigger.mapToVoid(),
                input.reset)
            .do(onNext: {
                selectedDrafts.onNext([])
            })
        
        let updateSelectedType = Driver
            .combineLatest(
                selectedDrafts.asDriverOnErrorJustComplete(),
                input.draftsCount,
                resultSelector: { (indexPaths: $0, count: $1) })
            .map({ (data) -> MultiSelectionType in
                if data.count == 0 {
                    return .normal
                }
                
                
                if data.indexPaths.count == MultiSelectionInput.Constant.limitSelection && tapSelectionAll {
                    return .selectAll(data.indexPaths.count)
                }
                
                if data.indexPaths.count == data.count && tapSelectionAll {
                    return .selectAll(data.indexPaths.count)
                }
                
                if data.indexPaths.count == 0 {
                    return .unselectAll
                }
                
                return .normal
            })
        
        let updateSelectedRow = input.selectOrDeselectInEditMode
            .withLatestFrom(selectedDrafts.asDriverOnErrorJustComplete(), resultSelector: { (indexPath: $0, selectedIndexPaths: $1) })
            .do(onNext: { (data) in
                var selectedIndexPaths = data.selectedIndexPaths
                tapSelectionAll = false

                if selectedIndexPaths.contains(data.indexPath) {
                    selectedIndexPaths.removeAll { (item) -> Bool in
                        if item == data.indexPath {
                            return true
                        }
                        
                        return false
                    }
                } else {
                    selectedIndexPaths.append(data.indexPath)
                }
                
                selectedDrafts.onNext(selectedIndexPaths)
            })
        
        let selectOrDeselectAllRows = input.selectOrDeselectAllDraftsTrigger
            .withLatestFrom(
                Driver.combineLatest(
                    updateSelectedType,
                    input.draftsCount,
                    resultSelector: ({(type: $0, count: $1)})))
            .do(onNext: { data in
                tapSelectionAll = true
                switch data.type {
                case .unselectAll:
                    var count: Int = data.count
                    
                    if data.count >= MultiSelectionInput.Constant.limitSelection {
                        count = MultiSelectionInput.Constant.limitSelection
                    }
                    
                    let allIndexPaths = (0..<count).map({ IndexPath(row: $0, section: 0) })
                    selectedDrafts.onNext(allIndexPaths)
                case .selectAll, .normal:
                    selectedDrafts.onNext([])
                }
            })
        
        let changeEvent = Driver
            .merge(
                resetSelectedDrafts,
                updateSelectedRow.mapToVoid(),
                selectOrDeselectAllRows.mapToVoid())
        
        // update title
        let titleDataStream = Driver
            .combineLatest(
                input.title,
                input.editingModeTrigger,
                selectedDrafts.asDriverOnErrorJustComplete(), resultSelector: {(normalTitle: $0, isEditing: $1, numOfDrafts: $2) })
        
        let title = changeEvent
            .withLatestFrom(titleDataStream)
            .map({ (data) -> String in
                if data.isEditing {
                    return L10n.Draft.EditMode.title(data.numOfDrafts.count)
                }

                return data.normalTitle
            })
        
        let items = changeEvent
            .withLatestFrom(selectedDrafts.asDriverOnErrorJustComplete())
        
        return MultiSelectionOutput(
            title: title,
            updateSelectedType: updateSelectedType,
            selectedDrafts: items)
    }
}
