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
        booksStore = BooksStore(storeType: .inMemory)
    }
    
    override func tearDown() {
        super.tearDown()
        booksStore = nil
    }
    
    var currentTestBook = 0
    
    /// Gets a fully populated BookMetadata object. Increments the ISBN by 1 each time.
    private func getTestBookMetadata() -> BookMetadata {
        currentTestBook += 1
        
        let testBookMetadata = BookMetadata()
        testBookMetadata.title = "Test Book Title \(currentTestBook)"
        testBookMetadata.authorList = "Test Book Authors \(currentTestBook)"
        testBookMetadata.bookDescription = "Test Book Description \(currentTestBook)"
        testBookMetadata.isbn13 = "123456789\(currentTestBook)"
        testBookMetadata.pageCount = 100 + currentTestBook
        testBookMetadata.publishedDate = Date(timeIntervalSince1970: 1488926352)
        return testBookMetadata
    }
    
    func testCreateNewBook() {
        let testBookMetadata = getTestBookMetadata()

        let readingInformation = BookReadingInformation()
        readingInformation.readState = .reading
        readingInformation.startedReading = Date(timeIntervalSince1970: 1488926352)
        
        // Create the book
        let book = booksStore.create(from: testBookMetadata, readingInformation: readingInformation)
        
        // Test that the metadata is all the same
        XCTAssertEqual(testBookMetadata.title, book.title)
        XCTAssertEqual(testBookMetadata.authorList, book.authorList)
        XCTAssertEqual(testBookMetadata.bookDescription, book.bookDescription)
        XCTAssertEqual(testBookMetadata.isbn13, book.isbn13)
        XCTAssertEqual(testBookMetadata.pageCount, book.pageCount as? Int)
        XCTAssertEqual(testBookMetadata.publishedDate, book.publishedDate)
        XCTAssertEqual(readingInformation.readState, book.readState)
        XCTAssertEqual(readingInformation.startedReading, book.startedReading)
        XCTAssertEqual(readingInformation.finishedReading, book.finishedReading)
    }
    
    func testThatSortOrderIncrements() {
        let toReadState = BookReadingInformation()
        toReadState.readState = .toRead
        
        let book1 = booksStore.create(from: getTestBookMetadata(), readingInformation: toReadState)
        let book2 = booksStore.create(from: getTestBookMetadata(), readingInformation: toReadState)
        
        XCTAssertEqual((book1.sort as! Int) + 1, (book2.sort as! Int))
    }
    
}
