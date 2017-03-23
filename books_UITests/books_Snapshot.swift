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
        
        // There's a weird glitch with the search bar when books are first added. Restart the app the fix it.
        app.terminate()
        app.launch()
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
        
        snapshot("0_ToReadList")
    }
}

