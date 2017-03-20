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
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSnapshot() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        snapshot("0EmptyToRead")
        
    }
}

