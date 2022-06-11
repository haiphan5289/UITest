//
//  LoadData.swift
//  GooDic
//
//  Created by ttvu on 6/5/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

/// helping to load data from file.
/// - Parameter filename: a filename loaded in Bundle
/// Ex: let users = load<[User]>("users.json")
func load<T: Decodable>(_ filename: String) -> T? {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            assertionFailure("Couldn't find \(filename) in main bundle.")
            return nil
        }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        assertionFailure("Couldn't load \(filename) from main bundle:\n\(error)")
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        assertionFailure("Couldn't parse \(filename) as \(T.self):\n\(error)")
        return nil
    }
}
