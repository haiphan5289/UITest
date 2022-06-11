//
//  FolderTC.swift
//  GooDicUITests
//
//  Created by haiphan on 18/05/2022.
//  Copyright © 2022 paxcreation. All rights reserved.
//

import XCTest

class FolderTC: UITCBase {
    
    enum SortModel {
        case title, update, create, manual
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func moveToFolder(app: XCUIApplication) {
        let toolBar = app.tabBars["タブバー"].buttons["フォルダ"]
        if toolBar.waitForExistence(timeout: 10) {
            toolBar.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    func btAddFolder(app: XCUIApplication) {
        let addFolder = app.buttons["ic addFolder"]
        if addFolder.waitForExistence(timeout: 10) {
            addFolder.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    func btCreateFolder(elementsQuery: XCUIElementQuery) {
        let btCreateFolder = elementsQuery.buttons["作成"]
        if btCreateFolder.waitForExistence(timeout: 10) {
            btCreateFolder.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    
    func inputTfNameFolder(nameFolder: String, elementsQuery: XCUIElementQuery) {
        let tfText = elementsQuery.textFields["新しいフォルダ"]
        if tfText.waitForExistence(timeout: 10) {
            tfText.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        tfText.typeText(nameFolder)
    }
    
    func detectedNameFolderIsExist(elementsQuery: XCUIElementQuery) {
        let lbError = elementsQuery.staticTexts["フォルダ名が重複しています。"]
        if lbError.waitForExistence(timeout: 10) {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func detectedNameFolderNil(elementsQuery: XCUIElementQuery) {
        let lbError = elementsQuery.staticTexts["フォルダ名を入力してください。"]
        if lbError.waitForExistence(timeout: 10) {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func moveToSortModel(app: XCUIApplication, sortModel: SortModel) {
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.tables.children(matching: .other).element.children(matching: .button).element.tap()
        switch sortModel {
        case .update:
            app.tables/*@START_MENU_TOKEN@*/.staticTexts["更新日"]/*[[".cells.staticTexts[\"更新日\"]",".staticTexts[\"更新日\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        case .title:
            app.tables/*@START_MENU_TOKEN@*/.staticTexts["タイトル"]/*[[".cells.staticTexts[\"タイトル\"]",".staticTexts[\"タイトル\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        case .manual: break
        default: break
        }
        
        app.navigationBars["並び替え"].buttons["Item"].tap()
    }
    
    func moveToSortManual(app: XCUIApplication) {
        let button = app.scrollViews.otherElements.tables.children(matching: .other).element.children(matching: .button).element
        if button.waitForExistence(timeout: 10) {
            button.tap()
        } else {
            XCTAssertTrue(false)
        }
        
        let selectManual = app.tables/*@START_MENU_TOKEN@*/.staticTexts["手動"]/*[[".cells.staticTexts[\"手動\"]",".staticTexts[\"手動\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        if selectManual.waitForExistence(timeout: 10) {
            selectManual.tap()
        } else {
            XCTAssertTrue(false)
        }
        
        if button.waitForExistence(timeout: 10) {
            button.tap()
        } else {
            XCTAssertTrue(false)
        }
    }

    func detectValueCell(app: XCUIApplication, index: Int, valueExpected: String, inputName: String) {
        let firstCell = app.tables.cells.element(boundBy: index)
        if firstCell.waitForExistence(timeout: 10) {
            let lbNameFolder = firstCell.staticTexts[inputName].label
            XCTAssertEqual(lbNameFolder, valueExpected, "Lỗi name")
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func buttonManual(app: XCUIApplication) {
        let buttonManual = app.tables/*@START_MENU_TOKEN@*/.staticTexts["手動"]/*[[".cells.staticTexts[\"手動\"]",".staticTexts[\"手動\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        if buttonManual.waitForExistence(timeout: 10) {
            buttonManual.tap()
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testCaseNameNil() throws {
        let app = XCUIApplication()
        app.launch()
        self.moveToFolder(app: app)
        self.btAddFolder(app: app)
        
        let elementsQuery = app.scrollViews.otherElements
        self.inputTfNameFolder(nameFolder: "", elementsQuery: elementsQuery)
        self.btCreateFolder(elementsQuery: elementsQuery)
        self.detectedNameFolderNil(elementsQuery: elementsQuery)
        
    }
    
    func testaddFolderSortManual() throws {
        let app = XCUIApplication()
        app.launch()
        self.moveToFolder(app: app)
        self.moveToSortManual(app: app)
        self.btAddFolder(app: app)
        
        let elementsQuery = app.scrollViews.otherElements
        self.inputTfNameFolder(nameFolder: "4444", elementsQuery: elementsQuery)
        self.btCreateFolder(elementsQuery: elementsQuery)
        self.detectValueCell(app: app, index: 1, valueExpected: "4444", inputName: "4444")
        
    }
    
    func testaddFolderSortTitle() throws {
        let app = XCUIApplication()
        app.launch()
        self.moveToFolder(app: app)
        self.moveToSortModel(app: app, sortModel: .title)
        self.btAddFolder(app: app)
        
        let elementsQuery = app.scrollViews.otherElements
        self.inputTfNameFolder(nameFolder: "3333", elementsQuery: elementsQuery)
        self.btCreateFolder(elementsQuery: elementsQuery)
        self.detectValueCell(app: app, index: 1, valueExpected: "3333", inputName: "3333")
    }
    
    func testaddFolderSortUpdateAt() throws {
        let app = XCUIApplication()
        app.launch()
        self.moveToFolder(app: app)
        self.moveToSortModel(app: app, sortModel: .update)
        self.btAddFolder(app: app)
        
        let elementsQuery = app.scrollViews.otherElements
        self.inputTfNameFolder(nameFolder: "2222", elementsQuery: elementsQuery)
        self.btCreateFolder(elementsQuery: elementsQuery)
        self.detectValueCell(app: app, index: 1, valueExpected: "2222", inputName: "2222")
    }
    
    func testCreateFolderIsExist() throws {
        let app = XCUIApplication()
        app.launch()
        self.moveToFolder(app: app)
        self.btAddFolder(app: app)
        
        let elementsQuery = app.scrollViews.otherElements
        self.inputTfNameFolder(nameFolder: "1111", elementsQuery: elementsQuery)
        self.btCreateFolder(elementsQuery: elementsQuery)
        self.detectedNameFolderIsExist(elementsQuery: elementsQuery)
    }
    
    func testCreateFolder() throws {
        
        let app = XCUIApplication()
        app.launch()
        self.moveToFolder(app: app)
        self.btAddFolder(app: app)
        
        let elementsQuery = app.scrollViews.otherElements
        self.inputTfNameFolder(nameFolder: "1111", elementsQuery: elementsQuery)
        self.btCreateFolder(elementsQuery: elementsQuery)
        sleep(1)

        //detect Add correctly
        let firstCell = app.tables.cells.element(boundBy: 1)
        if firstCell.waitForExistence(timeout: 10) {
            print("==== \(firstCell.staticTexts["1111"])")
//            firstCell.tap()
            XCTAssertTrue(firstCell.exists)
        } else {
            XCTAssertTrue(false)
        }
    }

    override func testExample() throws {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
