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
    
    func testAddAndDeleteManualBook() {
        let app = XCUIApplication()
        let initialNumberOfCells = app.tables.cells.count
        
        // Get to the Enter Manually page
        app.tabBars.buttons["Reading"].tap()
        app.navigationBars["Reading"].buttons["Add"].tap()
        app.sheets.buttons["Enter Manually"].tap()
        
        // Add some book metadata
        let nextButton = app.toolbars.children(matching: .button).element(boundBy: 1)
        app.textFields["Title"].tap()
        sleep(1)
        app.typeText("The Catcher in the Rye")
        app.textFields["Author"].tap()
        app.typeText("J. D. Salinger")
        nextButton.tap()
        app.typeText("241")
        nextButton.tap()
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "July")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "16")
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "1951")
        
        // Add reading state
        app.navigationBars["Add Manually"].buttons["Next"].tap()
        app.navigationBars["The Catcher in the Rye"].buttons["Done"].tap()
        sleep(1)
        
        // Verify we have 1 more row
        let oneMoreRow = UInt(initialNumberOfCells + 1)
        XCTAssertEqual(app.tables.cells.count, oneMoreRow)
        
        // Delete the book
        app.tables.children(matching: .cell).element(boundBy: initialNumberOfCells).tap()
        app.navigationBars["Reading_List.BookDetails"].buttons["Edit"].tap()
        //app.navigationBars.buttons["Edit"].tap()
        app.tables.staticTexts["Delete Book"].tap()
        app.sheets.buttons["Delete"].tap()
        sleep(1)
        
        // Verify the row has gone
        XCTAssertEqual(app.tables.cells.count, initialNumberOfCells)
    }
}
