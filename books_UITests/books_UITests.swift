//
//  books_UITests.swift
//  books_UITests
//
//  Created by Andrew Bennet on 25/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import XCTest

class books_UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInitialTables() {
        let app = XCUIApplication()
        let tabBarsQuery = app.tabBars
        
        XCTAssert(app.tabBars.buttons["Reading"].isSelected)
        XCTAssertEqual(app.tables.cells.count, 0)

        tabBarsQuery.buttons["Finished"].tap()
        XCTAssertEqual(app.tables.cells.count, 0)
        
        tabBarsQuery.buttons["Settings"].tap()
        XCTAssertNotEqual(app.tables.cells.count, 0)
    }
    
    func testAddManualBook() {
        let app = XCUIApplication()
        let nextButton = app.toolbars.children(matching: .button).element(boundBy: 1)
        
        app.tabBars.buttons["Reading"].tap()
        
        app.navigationBars["Reading"].buttons["Add"].tap()
        app.sheets.buttons["Enter Manually"].tap()
        
        app.textFields["Title"].tap()
        sleep(1)
        app.typeText("The Catcher in the Rye")
        
        nextButton.tap()
        app.typeText("J. D. Salinger")
        
        nextButton.tap()
        app.typeText("214")
        
        nextButton.tap()
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "July")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "16")
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "1951")
        
        app.navigationBars["Add Manually"].buttons["Next"].tap()
        app.navigationBars["Set Read State"].buttons["Done"].tap()
        XCTAssertEqual(app.tables.cells.count, 1)
    }
    
    func testDeleteBook(){
        let app = XCUIApplication()
        app.tables.children(matching: .cell).element(boundBy: 0).tap()
        app.toolbars.buttons["Edit"].tap()
        app.tables.staticTexts["Delete Book"].tap()
        app.sheets.buttons["Delete"].tap()
        
        sleep(1)
        XCTAssertEqual(app.tables.cells.count, 0)
    }
}
