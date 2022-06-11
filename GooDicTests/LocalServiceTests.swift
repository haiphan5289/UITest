//
//  LocalServiceTests.swift
//  GooDicTests
//
//  Created by ttvu on 5/21/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import XCTest
import GooDic

class LocalServiceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func test_IdiomAbnormal() {
//        let localService = IdiomService(gateway: IdiomLocalGateway())
//
//        localService.gateway.fetch(text: "Error").
//        localService.gateway.fetch(text: "Error") { (response) in
//            switch response {
//            case .failure(let error):
//                let error = error as! ServiceError
//                switch error {
//                case .error(let status, _):
//                    XCTAssertTrue(status == GooServices.kErrorStatus)
//                default:
//                    XCTAssertTrue(false, "this case's unexpected")
//                }
//            case .success(_):
//                XCTAssertTrue(false, "this case's unexpected")
//            }
//        }
//    }
    
//    func test_IdiomNormal() {
//        let localService = IdiomService(gateway: IdiomLocalGateway())
//
//        localService.gateway.fetch(text: "any data") { (response) in
//            switch response {
//            case .failure(_):
//                XCTAssertTrue(false, "this case's unexpected")
//            case .success(let list):
//                XCTAssertFalse(list.isEmpty, "this case's unexpected")
//            }
//        }
//    }
    
//    func test_ThesaurusAbnormal() {
//        let localService = ThesaurusService(gateway: ThesaurusLocalGateway())
//
//        localService.gateway.fetch(text: "Error") { (response) in
//            switch response {
//            case .failure(let error):
//                let error = error as! ServiceError
//                switch error {
//                case .error(let status, _):
//                    XCTAssertTrue(status == GooServices.kErrorStatus)
//                default:
//                    XCTAssertFalse(true, "this case's unexpected")
//                }
//            case .success(_):
//                XCTAssertFalse(true, "this case's unexpected")
//            }
//        }
//    }
    
//    func test_ThesaurusNormal() {
//        let localService = ThesaurusService(gateway: ThesaurusLocalGateway())
//
//        localService.gateway.fetch(text: "any data") { (response) in
//            switch response {
//            case .failure(_):
//                XCTAssertFalse(true, "this case's unexpected")
//            case .success(let list):
//                XCTAssertFalse(list.isEmpty, "this case's unexpected")
//            }
//        }
//    }
    
    func test_Dictionary() {
        let localService = DictionaryService(gateway: DictionaryLocalGateway())

        let url = localService.gateway.fetch(text: "acb", mode: .prefix)

        XCTAssertFalse(url == nil, "it should be url")
    }
}
