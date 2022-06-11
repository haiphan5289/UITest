//
//  SuggestionViewModel.swift
//  GooDic
//
//  Created by ttvu on 5/20/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

//struct ReplacementData {
//    let target: String
//    let replacement: String
//    let offset: Int
//
//    init(item: GDDataItem) {
//        self.target = item.name
//        self.replacement = item.activeName()
//        self.offset = item.offset
//    }
//}

struct SelectedTagData {
    let text: String
    let offset: Int // utf16.count
    let source: String
    let replacement: String
    let canRepalce: Bool
}

enum SuggestionDelegate {
    case dismiss
    case findTagOnTitle(SelectedTagData)
    case findTagOnContent(SelectedTagData)
}

struct SuggestionViewModel {
    let navigator: SuggestionNavigateProtocol!
    let useCase: SuggestionUseCaseProtocol!
    let delegate: PublishSubject<SuggestionDelegate>
    
    private var titleData: GDData!
    private var contentData: GDData!
    
    private var heights: [[CGFloat]] = []
    
    init(titleData: GDData, contentData: GDData, useCase: SuggestionUseCaseProtocol, navigator: SuggestionNavigateProtocol, delegate: PublishSubject<SuggestionDelegate>) {
        self.titleData = titleData
        self.contentData = contentData
        
        let numberOfTitleCell = self.titleData.items.count
        let numberOfContentCell = self.contentData.items.count
        let titleSection = [CGFloat](repeating: 0, count: numberOfTitleCell)
        let contentSection = [CGFloat](repeating: 0, count: numberOfContentCell)
        self.heights = [titleSection, contentSection]
        
        self.useCase = useCase
        self.navigator = navigator
        self.delegate = delegate
    }
    
    func titleDataSource() -> [GDDataItem] {
        return titleData.items
    }
    
    func contentDataSource() -> [GDDataItem] {
        return contentData.items
    }
}

extension SuggestionViewModel: ViewModelProtocol {
    enum SectionType: Int {
        case title = 0
        case content = 1
    }
    
    struct Input {
        var loadTrigger: Driver<Void>
        var dismissTrigger: Driver<Void>
        var feedbackTrigger: Driver<Void>
        var showInfoTrigger: Driver<String>
    }
    
    struct Output {
        var hasData: Driver<Bool>
        var dismiss: Driver<Void>
        var feedback: Driver<Void>
        var showInfo: Driver<Void>
    }
    
    func transform(_ input: Input) -> Output {
            let hasData = input.loadTrigger
                .map({ self.titleDataSource().count + self.contentDataSource().count != 0 })
            
            let dismiss = input.dismissTrigger
                .do(onNext: { (_) in
//                    self.navigator.dismiss()
                    self.delegate.onNext(.dismiss)
                })
            
            let feedback = input.feedbackTrigger
                .do(onNext: self.navigator.toFeedback)
            
            let showInfo = input.showInfoTrigger
                .compactMap(self.useCase.getDetail(path:))
                .do(onNext: self.navigator.toDetail(url:))
                .mapToVoid()
            
            return Output(
                hasData: hasData,
                dismiss: dismiss,
                feedback: feedback,
                showInfo: showInfo
            )
        }
        
        func titleForHeader(inSection section: Int) -> String? {
            return nil
//            if section == 0 {
//                return "title"
//            } else {
//                return "content"
//            }
        }
        
        func numberOfSections() -> Int {
            return 2
        }
        
        func numberOfItems(at section: Int) -> Int {
            if section == 0 {
                return titleDataSource().count
            } else {
                return contentDataSource().count
            }
        }
        
        func item(atIndexPath indexPath: IndexPath) -> GDDataItem? {
            if indexPath.section == 0 {
                if indexPath.row < titleDataSource().count {
                    return titleDataSource()[indexPath.row]
                }
            } else {
                if indexPath.row < contentDataSource().count {
                    return contentDataSource()[indexPath.row]
                }
            }
            
            return nil
        }
    
    
        
        mutating func updateCellHeight(atIndexPath indexPath: IndexPath, newValue: CGFloat) {
            if indexPath.section == 0{
                heights[0][indexPath.row] = newValue
            } else {
                heights[1][indexPath.row] = newValue
            }
        }
        
        func cellHeight(atIndexPath indexPath: IndexPath) -> CGFloat {
            if indexPath.section < heights.count{
                let currentSection = heights[indexPath.section]
                
                if indexPath.row < currentSection.count {
                    return currentSection[indexPath.row]
                }
            }
            
            return 0
        }
    
    
    func tapOn(tag tagType: TagType, section: Int, gdDataitemMain: GDDataItem?) {
        
        var data: GDData
        if section == 0 {
            data = self.titleData
        } else {
            data = self.contentData
        }
        
        let type = SectionType(rawValue: section) ?? SectionType.content
        let actionBlock: (SelectedTagData) -> Void = { (data: SelectedTagData) in
            switch type {
            case .title:
                self.delegate.onNext(.findTagOnTitle(data))
            case .content:
                self.delegate.onNext(.findTagOnContent(data))
            }
        }
        
        // text before selected a tag
        let text = data.text
        if case let TagType.suggestion(_, id, _) = tagType {
            let source = data.getItem(withId: id)?.activeName() ?? ""
            
            var captureId = id
            if let item = data.toggleItem(withId: id) {
                let newId = item.0 ?? ""
                let hasOver = item.1
                captureId = newId

                DispatchQueue.global(qos: .background).async {
                    var offset = data.getOffset(atId: id)
                    var replacement = data.getItem(withId: captureId)?.activeName() ?? ""
                    var canReplace: Bool = true
                    if hasOver {
                        replacement = source
                        canReplace = false
                        if let idMain = gdDataitemMain?.id {
                            offset = data.getOffset(atId: idMain)
                        }
                        data.updateTextWhenGreatLimit(withId: id, sourceLen: source, replacementText: replacement)
                    }

                    let data = SelectedTagData(text: text, offset: offset, source: source, replacement: replacement, canRepalce: canReplace)
                    DispatchQueue.main.async {
                        actionBlock(data)
                    }
                }
            }
        }
        else if case let TagType.main(_, id) = tagType {
            
            
            DispatchQueue.global(qos: .background).async {
                // send notification to search text
                let offset = data.getOffset(atId: id)
                let replacement = data.getItem(withId: id)?.activeName() ?? ""

                let data = SelectedTagData(text: text, offset: offset, source: replacement, replacement: replacement, canRepalce: true)

                DispatchQueue.main.async {
                    actionBlock(data)
                }
            }
        }
    }
    
    mutating func refreshHeightCell() {
        for section in 0...self.numberOfSections() - 1 {
            if self.numberOfItems(at: section) > 0 {
                for row in 0...self.numberOfItems(at: section) - 1 {
                    let index = IndexPath(row: row, section: section)
                    self.updateCellHeight(atIndexPath: index, newValue: 0)
                }
            }
        }
    }
    
//
//    func tapOn(tag tagType: TagType, section: Int) {
////        let type = SectionType(rawValue: section) ?? SectionType.content
////        let actionBlock: (SelectedTagData) -> Void = { (data: SelectedTagData) in
////            switch type {
////            case .title:
////                self.delegate.onNext(.findTagOnTitle(data))
////            case .content:
////                self.delegate.onNext(.findTagOnContent(data))
////            }
////        }
//
//        // text before selected a tag
////        let text = data.getRawContent()
//
//        let replacements = data.getSelectedItems().map({ ReplacementData(item: $0) })
//
//        if case let TagType.suggestion(_, id, _) = tagType {
////            let source = data.getItem(withId: id)?.activeName() ?? ""
//
//            var captureId = id
//            if let newId = data.toggleItem(withId: id) {
//                captureId = newId
//            }
//
//            if let currentItem = data.getItem(withId: captureId) {
//                let selectedData = SelectedTagData(text: "", offset: currentItem.offset, source: currentItem.name, replacements: replacements + [ReplacementData(item: currentItem)])
//                self.delegate.onNext(.findTag(selectedData))
//            }
//        }
//        else if case let TagType.main(_, id) = tagType {
//
//            if let currentItem = data.getItem(withId: id) {
//                let selectedData = SelectedTagData(text: "", offset: currentItem.offset, source: currentItem.name, replacements: replacements)
//                self.delegate.onNext(.findTag(selectedData))
//            }
//
//            DispatchQueue.global(qos: .background).async {
//                // send notification to search text
////                let startText = data.getRawContent(beforeId: id)
////                let index = startText.utf16.count
//
////
////                let data = SelectedTagData(text: text, index: index, source: replacement, replacement: replacement)
////
////                DispatchQueue.main.async {
////                    actionBlock(data)
////                }
//
//            }
//        }
//    }
}
