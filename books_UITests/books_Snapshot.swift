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
        
        let isIpad = app.navigationBars.count == 2
        
        if isIpad {
            XCUIDevice.shared().orientation = .landscapeLeft
            app.tables.cells.element(boundBy: 1).tap()
        }
        
        sleep(2)
        snapshot("0_ToReadList")
    }
}

