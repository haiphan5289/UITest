//
//  Encode+Extension.swift
//  AnimeDraw
//
//  Created by paxcreation on 12/14/20.
//

import UIKit

extension Encodable {
    func toData() throws -> Data {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return data
    }
}

extension Data {
    func toCodableObject<T: Codable>(type: T.Type) -> T? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        if let obj = try? decoder.decode(T.self, from: self) {
            return obj
        }
        return nil
    }
}
