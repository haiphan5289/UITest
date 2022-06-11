//
//  GDData.swift
//  GooDic
//
//  Created by ttvu on 6/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

struct GDDataItem {
    var id: String = UUID().uuidString
    var name: String
    var offset: Int
    var detailUrlPath: String?
    var suggestions: [GDSuggestionItem]
    
    init(name: String, offset: Int, detailUrlPath: String?, suggestions: [GDSuggestionItem]) {
        self.name = name
        self.offset = offset
        self.detailUrlPath = detailUrlPath
        self.suggestions = suggestions
    }
    
    func activeId() -> String {
        if let selectedItem = suggestions.first(where: { $0.isSelected }) {
            return selectedItem.id
        }
        
        return self.id
    }
    
    func activeName() -> String {
        if let selectedItem = suggestions.first(where: { $0.isSelected }) {
            return selectedItem.name
        }
        
        return self.name
    }
    
    func isActive() -> Bool {
        return suggestions.first(where: { $0.isSelected }) != nil ? true : false
    }
    
    mutating func updateSelectId(id: String) {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { return }
        suggestions[index].isSelected = false
    }
    
    // return new id
    mutating func toggle(at id: String) -> (String?, Bool)? {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { return nil }
        
        if suggestions[index].isSelected {
            suggestions[index].isSelected = false
            return (id, false)
        } else {
            for i in 0..<suggestions.count {
                suggestions[i].isSelected = false
            }
            suggestions[index].isSelected = true
            return (suggestions[index].id, true)
        }
    }
    
    func getIdSelect(at id: String) -> String? {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { return nil }
        if suggestions[index].isSelected {
            return id
        } else {
            return suggestions[index].id
        }
    }
    
    mutating func unSelectUndexCurrent(at id: String) {
        for i in 0..<suggestions.count {
            suggestions[i].isSelected = false
        }
    }
    
    mutating func selectWhenGreatThanLimited(at id: String) {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { return  }
        for i in 0..<suggestions.count {
            suggestions[i].isSelected = false
        }
        suggestions[index].isSelected = true
    }
    
    func hasId(id: String) -> Bool {
        return self.id == id || suggestions.contains(where: { $0.id == id })
    }
    
    static func from(data: IdiomData) -> GDDataItem {
        return GDDataItem(name: data.target,
                          offset: data.offset,
                          detailUrlPath: data.url,
                          suggestions: [GDSuggestionItem(name: data.correct, isSelected: false)])
    }
    
    static func from(data: ThesaurusData) -> GDDataItem {
        let list = data.list.map({ GDSuggestionItem(name: $0, isSelected: false) })
        return GDDataItem(name: data.target,
                          offset: data.offset,
                          detailUrlPath: data.url,
                          suggestions: list)
    }
}

struct GDSuggestionItem {
    var id: String = UUID().uuidString
    var name: String
    var isSelected: Bool
    
    init(name: String, isSelected: Bool) {
        self.name = name
        self.isSelected = isSelected
    }
}

class GDData {
    var text: String
    var items: [GDDataItem]
    var listSelectIndexId: [String?] = []
    
    init(text: String, items: [GDDataItem]) {
        self.text = text
        self.items = items
        self.createListSelect()
    }
    
    private func createListSelect() {
        listSelectIndexId = [String?](repeating: nil, count: self.items.count)
    }
    
//    func getContent(highlightId: String, highlightFGColor: UIColor, highlightBGColor: UIColor, foregroundColor: UIColor, font: UIFont) -> NSAttributedString {
//
//        guard let hlItem = getIncorrectItem(withId: highlightId) else { return NSAttributedString() }
//        let start = getRawContent(beforeId: highlightId)
//        let highlight = hlItem.activeName()
//        let end = getRawContent(afterId: highlightId)
//
//        let result = NSMutableAttributedString(string: start, attributes: [
//            NSAttributedString.Key.font: font,
//            NSAttributedString.Key.foregroundColor: foregroundColor
//        ])
//
//        result.append(NSAttributedString(string: highlight, attributes: [
//            NSAttributedString.Key.font: font,
//            NSAttributedString.Key.foregroundColor: highlightFGColor,
//            NSAttributedString.Key.backgroundColor: highlightBGColor,
//        ]))
//
//        result.append(NSAttributedString(string: end, attributes: [
//            NSAttributedString.Key.font: font,
//            NSAttributedString.Key.foregroundColor: foregroundColor
//        ]))
//
//        return result
//    }
    
    func getRawContent() -> String {
        return text
    }
    
    func getRawContent(afterId id: String, include: Bool = false) -> String {
        guard let index = items.firstIndex(where: { $0.hasId(id: id) }) else { return "" }
        let stringIndex = text.utf16.index(text.startIndex, offsetBy: items[index].offset)
        return String(text[stringIndex...])
    }
    
    func getRawContent(beforeId id: String) -> String {
        guard let index = items.firstIndex(where: { $0.hasId(id: id) }) else { return "" }
        let stringIndex = text.utf16.index(text.startIndex, offsetBy: items[index].offset)
        return String(text[..<stringIndex])
    }
    
    func getOffset(atId id: String) -> Int {
        guard let index = items.firstIndex(where: { $0.hasId(id: id) }) else { return 0 }
        return items[index].offset
    }
    
    func getItem(withId id: String) -> GDDataItem? {
        let result = items.first { (item) -> Bool in
            if item.id == id {
                return true
            } else {
                let ids = item.suggestions.map({ $0.id })
                return ids.contains(id)
            }
        }
        
        return result
    }
    
    func updateItem(withId id: String) {
        guard let selectedIndex = items.firstIndex(where: { item -> Bool in
            return item.hasId(id: id)
        }) else { return }
        items[selectedIndex].updateSelectId(id: id)
    }
    
//    func getTotalCountText(withId id: String) -> Int {
//        guard let selectedIndex = items.firstIndex(where: { item -> Bool in
//            return item.hasId(id: id)
//        }) else { return 0 }
//        let sourceLen = self.items[selectedIndex].activeName().utf16.count
//        if self.items[selectedIndex].getIdSelect(at: id) != nil {
//            let replacementText = self.items[selectedIndex].activeName()
//            let totalText = text.count - sourceLen + replacementText.count
//            return totalText
//        }
//        return 0
//    }
    
    func updateTextWhenGreatLimit(withId id: String, sourceLen: String, replacementText: String) {
        guard let selectedIndex = items.firstIndex(where: { item -> Bool in
            return item.hasId(id: id)
        }) else { return }
        let sourceLenCount = sourceLen.utf16.count
        let startIndex = text.utf16.index(text.startIndex, offsetBy: items[selectedIndex].offset)
        let endIndex = text.utf16.index(startIndex, offsetBy: sourceLenCount)
        text.replaceSubrange(startIndex..<endIndex, with: replacementText)
    }
    
    func updateUnSelect(withId id: String) {
        guard let selectedIndex = items.firstIndex(where: { item -> Bool in
            return item.hasId(id: id)
        }) else { return }
        self.items[selectedIndex].updateSelectId(id: id)
    }
    
    // return new id
    func toggleItem(withId id: String) -> (String?, Bool)? {
        guard let selectedIndex = items.firstIndex(where: { item -> Bool in
            return item.hasId(id: id)
        }) else { return (nil, false) }
        
        var hasGreatLimit: Bool = false
        let sourceLen = self.items[selectedIndex].activeName().utf16.count
        if let item = self.items[selectedIndex].toggle(at: id) {
            let newId = item.0
            let check = item.1
            var replacementText = self.items[selectedIndex].activeName()
            
            let startIndex = text.utf16.index(text.startIndex, offsetBy: items[selectedIndex].offset)
            let endIndex = text.utf16.index(startIndex, offsetBy: sourceLen)
            let totalText = text.count - sourceLen + replacementText.count
            
            if totalText > CreationUseCase.Constant.maxContent && !check {
                self.items[selectedIndex].selectWhenGreatThanLimited(at: id)
            } else if totalText > CreationUseCase.Constant.maxContent {
                replacementText = self.items[selectedIndex].activeName()
                if let idSelect = self.listSelectIndexId[selectedIndex], self.items[selectedIndex].isActive() {
                    self.items[selectedIndex].selectWhenGreatThanLimited(at: idSelect)
                }
                self.updateItem(withId: id)
                hasGreatLimit = true
            } else {
                self.listSelectIndexId[selectedIndex] = (self.items[selectedIndex].isActive()) ? id : nil
                text.replaceSubrange(startIndex..<endIndex, with: replacementText)
                let seek = sourceLen - replacementText.utf16.count
                if seek != 0 {
                    let currentOffset = self.items[selectedIndex].offset
                    // have to iterate from start of array because it's not an arranged.
                    for i in 0..<self.items.count {
                        if self.items[i].offset > currentOffset {
                            self.items[i].offset -= seek
                        }
                    }
                }
            }
            
            return (newId, hasGreatLimit)
        }
        
        return (nil, false)
    }
    
    func getSelectedItems() -> [GDDataItem] {
        return items.filter { (item: GDDataItem) -> Bool in
            return item.isActive()
        }
    }
}
