//
//  books_snapshot.swift
//  books_snapshot
//
//  Created by Andrew Bennet on 19/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import XCTest

class ReadingListApplication : XCUIApplication {
    enum tab : Int {
        case toRead = 0
        case finished = 1
        case settings = 2
    }
    
    enum addMethod : Int {
        case searchOnline = 1
        case enterManually = 2
    }
    
    var testDataAdded = false
    
    func clickTab(_ tab: tab) {
        tabBars.buttons.element(boundBy: UInt(tab.rawValue)).tap()
    }
    
    func addTestDataIfNotAdded() {
        guard testDataAdded == false else { return }
        
        clickTab(.settings)
        tables.cells.staticTexts["Use Test Data"].tap()
        sleep(5)
        testDataAdded = true
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

class books_snapshot: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        let app = ReadingListApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func screenshots() {
        
        let app = ReadingListApplication()
        
        snapshot("01EmptyReadingScreen")
        
        app.addTestDataIfNotAdded()
        
        app.clickTab(.finished)
        snapshot("02FinishedBooks")
        app.clickTab(.toRead)
        
        //app.navigationBars["Reading"].buttons["Edit"].tap()
        //let readingNavigationBar = app.navigationBars["Reading"]
        //readingNavigationBar.buttons["Done"].tap()
        
        app.topNavBar.buttons["Add"].tap()
        app.sheets.buttons["Search Online"].tap()
        app.searchFields["Search by Title or Author"].typeText("The City and the City")
        snapshot("03SearchByText")
        
        app.topNavBar.buttons["Cancel"].tap()
        
        app.tables.staticTexts["The City & The City"].tap()
        
    }
    
}
