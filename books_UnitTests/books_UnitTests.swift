//
//  books_UnitTests.swift
//  books_UnitTests
//
//  Created by Andrew Bennet on 04/11/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import XCTest
@testable import Reading_List

class books_UnitTests: XCTestCase {
    
    var booksStore: BooksStore!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        booksStore = BooksStore(storeType: .inMemory)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNewBook() {
        let testBookMetadata = BookMetadata()
        testBookMetadata.title = "Test Book Title"
        testBookMetadata.authorList = "Test Book Authors"
        testBookMetadata.bookDescription = "Test Book Description"
        testBookMetadata.isbn13 = "1234567891011"
        testBookMetadata.pageCount = 123
        testBookMetadata.publishedDate = Date(timeIntervalSince1970: 1488926352)

        let readingInformation = BookReadingInformation()
        readingInformation.readState = .reading
        readingInformation.startedReading = Date(timeIntervalSince1970: 1488926352)
        
        let book = booksStore.create(from: testBookMetadata, readingInformation: readingInformation)
        XCTAssert(testBookMetadata.title == book.title)
        XCTAssert(testBookMetadata.authorList == book.authorList)
        XCTAssert(testBookMetadata.bookDescription == book.bookDescription)
        XCTAssert(testBookMetadata.isbn13 == book.isbn13)
        //XCTAssert(testBookMetadata.pageCount == Int(book.pageCount))
        XCTAssert(testBookMetadata.publishedDate == book.publishedDate)
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
