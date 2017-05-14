//
//  books_UITests.swift
//  books_UITests
//
//  Created by Andrew Bennet on 25/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import XCTest

class ReadingListApplication : XCUIApplication {
    enum tab : Int {
        case toRead = 0
        case finished = 1
        case settings = 2
    }
    
    enum addMethod : Int {
        case scanBarcode = 0
        case searchOnline = 1
        case enterManually = 2
    }
    
    func clickTab(_ tab: tab) {
        getTab(tab).tap()
    }
    
    func getTab(_ tab: tab) -> XCUIElement {
        return tabBars.buttons.element(boundBy: UInt(tab.rawValue))
    }
    
    func waitUntilHittable(_ element: XCUIElement, failureMessage: String) {
        let startTime = NSDate.timeIntervalSinceReferenceDate
        
        while !element.isHittable {
            if NSDate.timeIntervalSinceReferenceDate - startTime > 30 {
                XCTAssert(false, failureMessage)
            }
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1, false)
        }
    }
    
    func addTestData() {
        clickTab(.settings)
        tables.cells.staticTexts["Debug Settings"].tap()
        
        let isIpad = navigationBars.count == 2
        tables.cells.staticTexts["Import Test Data"].tap()
        
        if isIpad {
            waitUntilHittable(getTab(.toRead), failureMessage: "Timeout waiting for test data to import")
        }
        else {
            let backButton = topNavBar.buttons["Settings"]
            waitUntilHittable(backButton, failureMessage: "Timeout waiting for test data to import")
            backButton.tap()
        }
    }
    
    func setBarcodeSimulation(_ mode: BarcodeScanSimulation) {
        clickTab(.settings)
        tables.cells.staticTexts["Debug Settings"].tap()
        
        tables.cells.staticTexts[mode.titleText].tap()
        if navigationBars.count == 1 {
            topNavBar.buttons["Settings"].tap()
        }
    }
    
    func clickAddButton(addMethod: addMethod) {
        navigationBars.element(boundBy: 0).buttons["Add"].tap()
        sheets.buttons.element(boundBy: UInt(addMethod.rawValue)).tap()
    }
    
    var topNavBar: XCUIElement {
        get {
            return navigationBars.element(boundBy: UInt(navigationBars.count - 1))
        }
    }
}

class books_UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        let app = ReadingListApplication()
        app.launch()

        // Add some test data
        app.addTestData()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddManualBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        
        let initialNumberOfCells = Int(app.tables.cells.count)
        app.clickAddButton(addMethod: .enterManually)
        
        // Add some book metadata
        app.textFields.element(boundBy: 0).tap()
        app.typeText("The Catcher in the Rye")
        app.textFields.element(boundBy: 1).tap()
        app.typeText("J. D. Salinger")
        
        app.topNavBar.buttons["Next"].tap()
        app.topNavBar.buttons["Done"].tap()
        
        sleep(1)
        XCTAssertEqual(app.tables.cells.count, UInt(initialNumberOfCells + 1))
    }
    
    func testEditBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        app.tables.cells.element(boundBy: 0).tap()
        app.topNavBar.buttons["Edit"].tap()
        app.sheets.buttons.element(boundBy: 1).tap()
        
        app.tables.staticTexts["Title"].tap()
        app.typeText("changed!")
        app.topNavBar.buttons["Done"].tap()
    }
    
    func testDeleteBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        let bookCount = Int(app.tables.element(boundBy: 0).cells.count)
        
        app.tables.cells.element(boundBy: 0).tap()
        app.topNavBar.buttons["Edit"].tap()
        app.sheets.buttons.element(boundBy: 1).tap()
        
        app.tables.staticTexts["Delete"].tap()
        app.sheets.buttons["Delete"].tap()
        
        sleep(1)
        XCTAssertEqual(app.tables.cells.count, UInt(bookCount - 1))
    }
    
    func testExportBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.settings)
        app.tables.staticTexts["Export Data"].tap()
        
        sleep(2)
        app.collectionViews.collectionViews.buttons["Add To iCloud Drive"].tap()
        app.navigationBars["iCloud Drive"].buttons["Cancel"].tap()
    }
    
    func testBarcodeScanner() {
        let app = ReadingListApplication()
        
        func scanBarcode(mode: BarcodeScanSimulation) {
            app.setBarcodeSimulation(mode)
            app.clickTab(.toRead)
        
            app.navigationBars["To Read"].buttons["Add"].tap()
            app.sheets.buttons["Scan Barcode"].tap()
        }
        
        // Normal mode
        scanBarcode(mode: .normal)
        sleep(1)
        app.topNavBar.buttons["Cancel"].tap()
        
        // No permissions
        scanBarcode(mode: .noCameraPermissions)
        sleep(1)
        XCTAssertEqual(app.alerts.count, 1)
        let permissionAlert = app.alerts.element(boundBy: 0)
        XCTAssertEqual("Permission Required", permissionAlert.label)
        permissionAlert.buttons["Cancel"].tap()
        
        // Valid ISBN
        scanBarcode(mode: .validIsbn)
        sleep(5)
        app.topNavBar.buttons["Done"].tap()
        
        // Not found ISBN
        scanBarcode(mode: .unfoundIsbn)
        sleep(2)
        XCTAssertEqual(app.alerts.count, 1)
        let noMatchAlert = app.alerts.element(boundBy: 0)
        XCTAssertEqual("No Exact Match", noMatchAlert.label)
        noMatchAlert.buttons["No"].tap()
        app.topNavBar.buttons["Cancel"].tap()
        
        // Existing ISBN
        scanBarcode(mode: .existingIsbn)
        sleep(1)
        XCTAssertEqual(app.alerts.count, 1)
        let duplicateAlert = app.alerts.element(boundBy: 0)
        XCTAssertEqual("Book Already Added", duplicateAlert.label)
        duplicateAlert.buttons["Cancel"].tap()
        app.topNavBar.buttons["Cancel"].tap()
    }
}
