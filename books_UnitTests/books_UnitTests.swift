//
//  books_UnitTests.swift
//  books_UnitTests
//
//  Created by Andrew Bennet on 04/11/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import XCTest
import Foundation
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
    
    
    static func days(_ count: Int) -> DateComponents {
        var component = DateComponents()
        component.day = count
        return component
    }
    
    private let yesterday = Date.startOfToday().date(byAdding: books_UnitTests.days(-1))!
    private let today = Date.startOfToday()
    private let tomorrow = Date.startOfToday().date(byAdding: books_UnitTests.days(1))!
    
    var currentTestBook = 0
    
    /// Gets a fully populated BookMetadata object. Increments the ISBN by 1 each time.
    private func getTestBookMetadata() -> BookMetadata {
        currentTestBook += 1
        let testBookMetadata = BookMetadata()
        testBookMetadata.title = "Test Book Title \(currentTestBook)"
        testBookMetadata.authorList = "Test Book Authors \(currentTestBook)"
        testBookMetadata.bookDescription = "Test Book Description \(currentTestBook)"
        testBookMetadata.isbn13 = "1234567890\(String(format: "%03d", currentTestBook))"
        testBookMetadata.pageCount = 100 + currentTestBook
        testBookMetadata.publishedDate = Date(timeIntervalSince1970: 1488926352)
        return testBookMetadata
    }
    
    func testBookMetadataPopulates() {
        let testBookMetadata = getTestBookMetadata()
        let readingInformation = BookReadingInformation.finished(started: yesterday, finished: today)
        
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
        let toReadState = BookReadingInformation.toRead()
        let book1 = booksStore.create(from: getTestBookMetadata(), readingInformation: toReadState)
        let book2 = booksStore.create(from: getTestBookMetadata(), readingInformation: toReadState)
        
        XCTAssertEqual((book1.sort as! Int) + 1, (book2.sort as! Int))
    }
    
    func testSortIndexRemovedWhenStarted() {
        let toReadState = BookReadingInformation.toRead()
        let book = booksStore.create(from: getTestBookMetadata(), readingInformation: toReadState)
        
        let reading = BookReadingInformation.reading(started: today)
        booksStore.update(book: book, with: reading)
        
        XCTAssertNil(book.sort)
    }
    
    func testToReadBookOrdering() {
        let fetchedResultsController = booksStore.fetchedResultsController(BookPredicate.readState(equalTo: .toRead), initialSortDescriptors: BooksStore.standardSortOrder)
        
        let first = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.toRead())
        let second = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.toRead())
        
        try! fetchedResultsController.performFetch()
        XCTAssertEqual(first, fetchedResultsController.object(at: IndexPath(item: 0, section: 0)))
        XCTAssertEqual(second, fetchedResultsController.object(at: IndexPath(item: 1, section: 0)))
    }
    
    func testReadingBookOrdering() {
        let fetchedResultsController = booksStore.fetchedResultsController(BookPredicate.readState(equalTo: .reading), initialSortDescriptors: BooksStore.standardSortOrder)
        
        let past = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.reading(started: yesterday))
        let future = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.reading(started: tomorrow))
        let present = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.reading(started: today))
        
        try! fetchedResultsController.performFetch()
        XCTAssertEqual(future, fetchedResultsController.object(at: IndexPath(item: 0, section: 0)))
        XCTAssertEqual(present, fetchedResultsController.object(at: IndexPath(item: 1, section: 0)))
        XCTAssertEqual(past, fetchedResultsController.object(at: IndexPath(item: 2, section: 0)))
    }
    
    func testFinishedBookOrdering() {
        let fetchedResultsController = booksStore.fetchedResultsController(BookPredicate.readState(equalTo: .finished), initialSortDescriptors: BooksStore.standardSortOrder)
        
        let past1 = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.finished(started: tomorrow, finished: yesterday))
        let past2 = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.finished(started: yesterday, finished: yesterday))
        
        let future1 = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.finished(started: tomorrow, finished: tomorrow))
        let future2 = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.finished(started: yesterday, finished: tomorrow))
        
        let present1 = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.finished(started: tomorrow, finished: today))
        let present2 = booksStore.create(from: getTestBookMetadata(), readingInformation: BookReadingInformation.finished(started: yesterday, finished: today))
        
        try! fetchedResultsController.performFetch()
        XCTAssertEqual(future1, fetchedResultsController.object(at: IndexPath(item: 0, section: 0)))
        XCTAssertEqual(future2, fetchedResultsController.object(at: IndexPath(item: 1, section: 0)))
        XCTAssertEqual(present1, fetchedResultsController.object(at: IndexPath(item: 2, section: 0)))
        XCTAssertEqual(present2, fetchedResultsController.object(at: IndexPath(item: 3, section: 0)))
        XCTAssertEqual(past1, fetchedResultsController.object(at: IndexPath(item: 4, section: 0)))
        XCTAssertEqual(past2, fetchedResultsController.object(at: IndexPath(item: 5, section: 0)))
    }
    
    func testIsbnDetection() {
        let testBook = getTestBookMetadata()
        XCTAssertFalse(booksStore.isbnExists(testBook.isbn13!))
        booksStore.create(from: testBook, readingInformation: BookReadingInformation.toRead())
        XCTAssertTrue(booksStore.isbnExists(testBook.isbn13!))
    }
    
    func testHumanisedDateString() {
        XCTAssertEqual("Today", today.toShortPrettyString())
    }
    
}
