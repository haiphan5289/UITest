//
//  DatabaseService.swift
//  GooDic
//
//  Created by ttvu on 6/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation
import RxSwift

public protocol DatabaseGatewayProtocol {
    func get(document: Document) -> Observable<CDDocument>
    func bin(document: Document) -> Observable<Void>
    func pushBack(document: Document) -> Observable<Void>
    func delete(documents: [Document]) -> Observable<Void>
    func update(document: Document, updateDate: Bool) -> Observable<Void>
    func create(document: Document) -> Observable<Void>
    
    func getFolder(with name: String) -> Observable<[CDFolder]>
    func move(document: Document, to folderId: String) -> Observable<Void>
    func update(folder: Folder) -> Observable<Void>
    func delete(folder: Folder) -> Observable<Void>
    
    func getUncategorizedDocuments() -> Observable<[CDDocument]>
    func getAllDocuments() -> Observable<[CDDocument]>
    func updateSort(folder: Folder)
    func updateDocs(document: Document, updateDate: Bool)
    func checkIsDocument(document: Document) -> Bool
    func getFolder(with name: String) -> [CDFolder]
}

public typealias DatabaseService = GooService<DatabaseGatewayProtocol>
