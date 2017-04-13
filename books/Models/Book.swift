//
//  book.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData

@objc(Book)
class Book: NSManagedObject {
    // The fields on this managed object have private setters, to enforce that the properties are internally consistent.
    
    // Book Metadata
    @NSManaged fileprivate(set) var title: String
    @NSManaged fileprivate(set) var authorList: String?
    @NSManaged fileprivate(set) var isbn13: String?
    @NSManaged fileprivate(set) var googleBooksId: String?
    @NSManaged fileprivate(set) var pageCount: NSNumber?
    @NSManaged fileprivate(set) var publishedDate: Date?
    @NSManaged fileprivate(set) var bookDescription: String?
    @NSManaged fileprivate(set) var coverImage: Data?
    
    // Reading Information
    @NSManaged fileprivate(set) var readState: BookReadState
    @NSManaged fileprivate(set) var startedReading: Date?
    @NSManaged fileprivate(set) var finishedReading: Date?
    
    // Other Metadata
    // TODO: Think about making this privately set, and managing its value internally
    @NSManaged var sort: NSNumber?
    @NSManaged var createdWhen: Date
}

/// The availale reading progress states
@objc enum BookReadState : Int32, CustomStringConvertible {
    case reading = 1
    case toRead = 2
    case finished = 3
    
    var description: String {
        switch self{
        case .reading:
            return "Reading"
        case .toRead:
            return "To Read"
        case .finished:
            return "Finished"
        }
    }
}


extension Book {

    func populate(from metadata: BookMetadata) {
        title = metadata.title
        authorList = metadata.authors
        isbn13 = metadata.isbn13
        googleBooksId = metadata.googleBooksId
        pageCount = metadata.pageCount as NSNumber?
        publishedDate = metadata.publishedDate
        bookDescription = metadata.bookDescription
        coverImage = metadata.coverImage
    }
    
    func populate(from readingInformation: BookReadingInformation) {
        readState = readingInformation.readState
        startedReading = readingInformation.startedReading?.startOfDay()
        finishedReading = readingInformation.finishedReading?.startOfDay()
        // Wipe out the sort if we have moved out of this section
        if readState != .toRead {
            sort = nil
        }
    }
    
    func toSpotlightItem() -> SpotlightItem {
        let spotlightTitle = "\(title)\(authorList == nil ? "" : " - \(authorList!)")"
        
        return SpotlightItem(uniqueIdentifier: objectID.uriRepresentation().absoluteString, title: spotlightTitle, description: bookDescription, thumbnailImageData: coverImage)
    }
    
    static let transistionToReadingStateAction = GeneralUIAction<Book>(style: .normal, title: "Start") { book in
        let reading = BookReadingInformation(readState: .reading, startedWhen: Date(), finishedWhen: nil)
        appDelegate.booksStore.update(book: book, withReadingInformation: reading)
    }
    
    static let transistionToFinishedStateAction = GeneralUIAction<Book>(style: .normal, title: "Finish") { book in
        let finished = BookReadingInformation(readState: .finished, startedWhen: book.startedReading!, finishedWhen: Date())
        appDelegate.booksStore.update(book: book, withReadingInformation: finished)
    }
    
    static let deleteAction = GeneralUIAction<Book>(style: .destructive, title: "Delete") { book in
        appDelegate.booksStore.delete(book)
    }
    
    static let csvExport = CsvExport<Book>(columns:
        CsvColumn<Book>(header: "ISBN-13", cellValue: {$0.isbn13}),
        CsvColumn<Book>(header: "Google Books ID", cellValue: {$0.googleBooksId}),
        CsvColumn<Book>(header: "Title", cellValue: {$0.title}),
        CsvColumn<Book>(header: "Author", cellValue: {$0.authorList}),
        CsvColumn<Book>(header: "Page Count", cellValue: {$0.pageCount == nil ? nil : String(describing: $0.pageCount!)}),
        CsvColumn<Book>(header: "Description", cellValue: {$0.bookDescription}),
        CsvColumn<Book>(header: "Started Reading", cellValue: {$0.startedReading?.toString(withDateFormat: "yyyy-MM-dd")}),
        CsvColumn<Book>(header: "Finished Reading", cellValue: {$0.finishedReading?.toString(withDateFormat: "yyyy-MM-dd")})
    )
}


/// A mutable, non-persistent representation of the metadata fields of a Book object.
/// Useful for maintaining in-creation books, or books being edited.
class BookMetadata {
    let googleBooksId: String?
    var title: String
    var authors: String
    var pageCount: Int?
    var publishedDate: Date?
    var bookDescription: String?
    var isbn13: String?
    var coverImage: Data?
    
    // ONLY used for import; not a usually populated field
    var coverUrl: URL?
    
    init(googleBooksId: String? = nil, title: String, authors: String) {
        self.googleBooksId = googleBooksId
        self.title = title
        self.authors = authors
    }
    
    init(book: Book) {
        self.title = book.title
        self.authors = book.authorList!
        self.bookDescription = book.bookDescription
        self.pageCount = book.pageCount as? Int
        self.publishedDate = book.publishedDate
        self.coverImage = book.coverImage
        self.isbn13 = book.isbn13
        self.googleBooksId = book.googleBooksId
    }
    
    static func csvImport(csvData: [String: String]) -> (BookMetadata, BookReadingInformation)? {
        
        guard let title = csvData["Title"], let authors = csvData["Author"] else { return nil }
        let bookMetadata = BookMetadata(googleBooksId: csvData["Google Books ID"]?.nilIfWhitespace(), title: title, authors: authors)
        bookMetadata.isbn13 = Isbn13.tryParse(inputString: csvData["ISBN-13"])
        bookMetadata.pageCount = csvData["Page Count"] == nil ? nil : Int(csvData["Page Count"]!)
        bookMetadata.bookDescription = csvData["Description"]?.nilIfWhitespace()
        bookMetadata.coverUrl = URL(optionalString: csvData["Cover URL"])
        
        let startedReading = Date(dateString: csvData["Started Reading"])
        let finishedReading = Date(dateString: csvData["Finished Reading"])

        let readingInformation: BookReadingInformation
        if startedReading != nil && finishedReading != nil {
            readingInformation = BookReadingInformation.finished(started: startedReading!, finished: finishedReading!)
        }
        else if startedReading != nil && finishedReading == nil {
            readingInformation = BookReadingInformation.reading(started: startedReading!)
        }
        else {
            readingInformation = BookReadingInformation.toRead()
        }
        return (bookMetadata, readingInformation)
    }
}

/// A mutable, non-persistent representation of a the reading status of a Book object.
/// Useful for maintaining in-creation books, or books being edited.
class BookReadingInformation {
    // TODO: consider create class heirachy with non-optional Dates where appropriate
    
    let readState: BookReadState
    let startedReading: Date?
    let finishedReading: Date?
    
    /// Will only populate the start date if started; will only populate the finished date if finished.
    /// Otherwise, dates are set to nil.
    init(readState: BookReadState, startedWhen: Date?, finishedWhen: Date?) {
        self.readState = readState
        switch readState {
        case .toRead:
            self.startedReading = nil
            self.finishedReading = nil
        case .reading:
            self.startedReading = startedWhen!
            self.finishedReading = nil
        case .finished:
            self.startedReading = startedWhen!
            self.finishedReading = finishedWhen!
        }
    }
    
    static func toRead() -> BookReadingInformation {
        return BookReadingInformation(readState: .toRead, startedWhen: nil, finishedWhen: nil)
    }
    
    static func reading(started: Date) -> BookReadingInformation {
        return BookReadingInformation(readState: .reading, startedWhen: started, finishedWhen: nil)
    }
    
    static func finished(started: Date, finished: Date) -> BookReadingInformation {
        return BookReadingInformation(readState: .finished, startedWhen: started, finishedWhen: finished)
    }
}


