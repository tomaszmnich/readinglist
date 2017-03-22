//
//  books_Snapshot.swift
//  books
//
//  Created by Andrew Bennet on 20/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//


import XCTest

class books_Snapshot: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let app = ReadingListApplication()
        setupSnapshot(app)
        app.launch()
        app.addTestData()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSnapshot() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        app.tables.cells.element(boundBy: 1).tap()
        // Press back if not in split screen
        if app.topNavBar.buttons.count >= 2 {
            app.topNavBar.buttons.element(boundBy: 0).tap()
        }
        app.tables.element(boundBy: 0).swipeUp()
        app.tables.element(boundBy: 0).swipeDown()
        
        snapshot("0_ToReadList")
    }
}

