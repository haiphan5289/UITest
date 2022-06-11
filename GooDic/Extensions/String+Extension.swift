//
//  String+Extension.swift
//  GooDic
//
//  Created by ttvu on 6/19/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    // MARK: - Split with Key and Order
    // split arranged keys, find first index
    func split(withArrangedOrders dataList: inout [GooDataProtocol], fromIndex: String.Index) -> [String] {
        var result: [String] = []
        var source = self
        var lastIndex: String.Index = fromIndex
        let pairs = dataList
        
        var countRemovedItem = 0
        for i in 0..<pairs.count {
            let item = pairs[i]
        
            if item.target.isEmpty {
                dataList.remove(at: i - countRemovedItem)
                countRemovedItem += 1
            }
            
            let range: Range<String.Index>?
            
            if item.order != -1 {
                range = self.findIndex(key: item.target, order: item.order)
            } else {
                range = self.range(of: item.target, range: Range(uncheckedBounds: (lower: lastIndex, upper: self.endIndex)))
            }
            
            if let range = range {
                let list = self.splitTwoElement(from: lastIndex, range: range)
                if list.count != 2 {
                    dataList.remove(at: i - countRemovedItem)
                    countRemovedItem += 1
                } else {
                    result.append(list[0])
                    result.append(item.target)
                    
                    source = list[1]
                    lastIndex = range.upperBound
                }
            }
        }
        
        result.append(source)
        
        return result
    }
    
    func splitTwoElement(from: String.Index?, range: Range<String.Index>) -> [String] {
        let start = from ?? startIndex
        
        if start > range.lowerBound {
            return []
        }
        
        let first = String(self[start..<range.lowerBound])
        let last = String(self.suffix(from: range.upperBound))
        return [first, last]
    }
    
    func findIndex(key: String, order: Int) -> Range<String.Index>? {
        if order <= 0 {
            return nil
        }
        
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: key, range: searchRange) {
            count += 1
            
            if count == order {
                return foundRange
            }
            
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        
        return nil
    }
    
    // MARK: - Split with Key and Offset
    // split string with arranged keys and offset
    func split(withArrangedOffset pairs: [(key: String, position: Int)]) -> [String] {
        var result: [String] = []
        var source = self
        for pair in pairs {
            if let list = source.splitTwoElement(separatedBy: pair.position, length: pair.key.count) {
                result.append(list[0])
                result.append(pair.key)
                
                source = list[1]
            } else {
                break
            }
        }
        
        result.append(source)
        
        return result
    }
    
    func splitTwoElement(separatedBy position: Int, length: Int) -> [String]? {
        if position > self.count
            || position + length > self.count
            || position < 0
            || length < 0 {
            
            return nil
        }
        
        let first = String(self.prefix(position))
        let last = String(self.suffix(position + length))
        return [first, last]
    }
    
    func getAttributedString(attributes2: [NSAttributedString.Key : Any]) -> NSMutableAttributedString {
        let myMutableString = NSMutableAttributedString(string: self, attributes: attributes2)
        return myMutableString
        
    }
    
    func getAttributedStringALL(attributes: [NSAttributedString.Key : Any]) -> NSMutableAttributedString {
        let myMutableString = NSMutableAttributedString(string: self, attributes: attributes)
        return myMutableString
        
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
