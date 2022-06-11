//
//  GooDicUITests.swift
//  GooDicUITests
//
//  Created by ttvu on 5/15/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import XCTest

class GooDicUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testChangeNameFont2() throws {
        
        let app = XCUIApplication()
        app.launch()

        let toolBar = app.tabBars["タブバー"].buttons["フォルダ"]
        if toolBar.waitForExistence(timeout: 10) {
            toolBar.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }

        let addFolder = app.buttons["ic addFolder"]
        if addFolder.waitForExistence(timeout: 10) {
            addFolder.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }

        let elementsQuery = app.scrollViews.otherElements
        let tfText = elementsQuery.textFields["新しいフォルダ"]
        if addFolder.waitForExistence(timeout: 10) {
            tfText.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        tfText.typeText("1111")

        let btCreateFolder = elementsQuery.buttons["作成"]
        if btCreateFolder.waitForExistence(timeout: 10) {
            btCreateFolder.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        sleep(2)
        
//        let app = XCUIApplication()
//        app.tabBars["タブバー"].buttons["フォルダ"].tap()
//        app.scrollViews.otherElements.tables/*@START_MENU_TOKEN@*/.staticTexts["1111"]/*[[".cells.staticTexts[\"1111\"]",".staticTexts[\"1111\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//
//        let firstCell = app.tables.cells.element(boundBy: 1)
//        if firstCell.waitForExistence(timeout: 10) {
//            print("==== \(firstCell.staticTexts["1111"])")
////            firstCell.tap()
//            XCTAssertTrue(firstCell.exists)
//        } else {
//            XCTAssertTrue(false)
//            waitForExpectations(timeout: 10, handler: nil)
//        }
    }
    
    func testChangeNameFont() throws {
        
        let app = XCUIApplication()
        app.launch()
        let buttonAdd = app.buttons["ic addDraft"]
        if buttonAdd.waitForExistence(timeout: 10) {
            buttonAdd.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        let buttonSetting = app.navigationBars["0字"].buttons["ic setting header"]
        if buttonSetting.waitForExistence(timeout: 10) {
            buttonSetting.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["明朝"]/*[[".cells.buttons[\"明朝\"]",".buttons[\"明朝\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery.buttons["ゴシック"].tap()
        sleep(1)
        self.takeScreenshot(named: "testChangeNameFont")
    }
    
    func testCanotMaximum() throws {
        let app = XCUIApplication()
        app.launch()
//        app.launchArguments.append("--libiScreenshots")
        
        let buttonAdd = app.buttons["ic addDraft"]
//        let exists = NSPredicate(format: "exists == 1")
//        expectation(for: exists, evaluatedWith: buttonAdd, handler: nil)
        if buttonAdd.waitForExistence(timeout: 10) {
            buttonAdd.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
    
        let buttonSetting = app.navigationBars["0字"].buttons["ic setting header"]
        if buttonSetting.waitForExistence(timeout: 10) {
            buttonSetting.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        
        let tablesQuery = app.tables
        let buttonActive = tablesQuery/*@START_MENU_TOKEN@*/.buttons["ic plus active"]/*[[".cells.buttons[\"ic plus active\"]",".buttons[\"ic plus active\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        if buttonActive.waitForExistence(timeout: 10) {
            buttonActive.tap()
        } else {
            XCTAssertFalse(false)
        }
        self.takeScreenshot(named: "testCanotMaximum")
    }
    
    func testCaseCanotMinimum() throws {
        let app = XCUIApplication()
        app.launch()
//        app.launchArguments.append("--libiScreenshots")
        
        let buttonAdd = app.buttons["ic addDraft"]
//        let exists = NSPredicate(format: "exists == 1")
//        expectation(for: exists, evaluatedWith: buttonAdd, handler: nil)
        if buttonAdd.waitForExistence(timeout: 10) {
            buttonAdd.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
    
        let buttonSetting = app.navigationBars["0字"].buttons["ic setting header"]
        if buttonSetting.waitForExistence(timeout: 10) {
            buttonSetting.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        
        let tablesQuery = app.tables
        let buttonMinus = tablesQuery/*@START_MENU_TOKEN@*/.buttons["ic minus active"]/*[[".cells.buttons[\"ic minus active\"]",".buttons[\"ic minus active\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        if buttonMinus.waitForExistence(timeout: 10) {
            buttonMinus.tap()
        } else {
            XCTAssertFalse(false)
        }
        self.takeScreenshot(named: "testCaseCanotMinimum")
        
    }
    
    
    func testCheck() throws {
        let app = XCUIApplication()
        app.launch()
//        app.launchArguments.append("--libiScreenshots")
        
        let buttonAdd = app.buttons["ic addDraft"]
//        let exists = NSPredicate(format: "exists == 1")
//        expectation(for: exists, evaluatedWith: buttonAdd, handler: nil)
        if buttonAdd.waitForExistence(timeout: 10) {
            buttonAdd.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
    
        let buttonSetting = app.navigationBars["0字"].buttons["ic setting header"]
        if buttonSetting.waitForExistence(timeout: 10) {
            buttonSetting.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        
        
        let tablesQuery = app.tables
        let buttonActive = tablesQuery/*@START_MENU_TOKEN@*/.buttons["ic plus active"]/*[[".cells.buttons[\"ic plus active\"]",".buttons[\"ic plus active\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        if buttonActive.waitForExistence(timeout: 10) {
            buttonActive.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        sleep(2)
        let buttonMinus = tablesQuery/*@START_MENU_TOKEN@*/.buttons["ic minus active"]/*[[".cells.buttons[\"ic minus active\"]",".buttons[\"ic minus active\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        if buttonMinus.waitForExistence(timeout: 10) {
            buttonMinus.tap()
        } else {
            waitForExpectations(timeout: 10, handler: nil)
        }
        self.takeScreenshot(named: "testCheck")
        
    }
    
    func takeScreenshot(named name: String) {
        // Take the screenshot
        let fullScreenshot = XCUIScreen.main.screenshot()
        
        // Create a new attachment to save our screenshot
        // and give it a name consisting of the "named"
        // parameter and the device name, so we can find
        // it later.
        let screenshotAttachment = XCTAttachment(
            uniformTypeIdentifier: "public.png",
            name: "Screenshot-\(UIDevice.current.name)-\(name).png",
            payload: fullScreenshot.pngRepresentation,
            userInfo: nil)
            
        // Usually Xcode will delete attachments after
        // the test has run; we don't want that!
        screenshotAttachment.lifetime = .keepAlways
        
        // Add the attachment to the test log,
        // so we can retrieve it later
        add(screenshotAttachment)
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
