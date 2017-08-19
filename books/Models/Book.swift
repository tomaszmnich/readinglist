//
//  book.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData

class BookMapping_6_7: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        let newBook = NSEntityDescription.insertNewObject(forEntityName: "Book", into: manager.destinationContext)
        
        func copyValue(forKey key: String) {
            newBook.setValue(sInstance.value(forKey: key), forKey: key)
        }
        
        copyValue(forKey: "title")
        copyValue(forKey: "isbn13")
        copyValue(forKey: "googleBooksId")
        copyValue(forKey: "pageCount")
        copyValue(forKey: "publicationDate")
        copyValue(forKey: "bookDescription")
        copyValue(forKey: "coverImage")
        copyValue(forKey: "readState")
        copyValue(forKey: "startedReading")
        copyValue(forKey: "finishedReading")
        copyValue(forKey: "notes")
        copyValue(forKey: "currentPage")
        copyValue(forKey: "sort")
        copyValue(forKey: "createdWhen")
        let sourceSubjects = (sInstance.value(forKey: "subjects") as! NSOrderedSet).map{$0 as! NSManagedObject}
        let destinationSubjects = manager.destinationInstances(forEntityMappingName: "SubjectToSubject",
                                      sourceInstances: sourceSubjects)
        newBook.setValue(NSOrderedSet(array: destinationSubjects), forKey: "subjects")

        var authors = [NSManagedObject]()
        for authorString in ((sInstance.value(forKey: "authorList") as! String).components(separatedBy: ",").flatMap{$0.trimming().nilIfWhitespace()}) {
            var authorDetails: (lastName: String, firstNames: String?)?
            if let range = authorString.range(of: " ", options: .backwards),
                let lastName = authorString.substring(from: range.upperBound).trimming().nilIfWhitespace() {
                authorDetails = (lastName: lastName,
                                 firstNames: authorString.substring(to: range.upperBound).trimming().nilIfWhitespace())
            }
            else {
                authorDetails = (lastName: authorString, firstNames: nil)
            }
            
            if let authorDetails = authorDetails {
                let newAuthor = NSEntityDescription.insertNewObject(forEntityName: "Author", into: manager.destinationContext)
                newAuthor.setValue(authorDetails.lastName, forKey: "lastName")
                newAuthor.setValue(authorDetails.firstNames, forKey: "firstNames")
                authors.append(newAuthor)
            }
            
        }
        newBook.setValue(NSOrderedSet(array: authors), forKey: "authors")
    }
}

@objc(Author)
public class Author: NSManagedObject {
    @NSManaged var lastName: String
    @NSManaged var firstNames: String?
    @NSManaged var book: Book!

    override public func willSave() {
        super.willSave()
        if !isDeleted && book == nil {
            managedObjectContext?.delete(self)
        }
    }
}

@objc(Book)
public class Book: NSManagedObject {   
    // Book Metadata
    @NSManaged var title: String
    @NSManaged var isbn13: String?
    @NSManaged var googleBooksId: String?
    @NSManaged var pageCount: NSNumber?
    @NSManaged var publicationDate: Date?
    @NSManaged var bookDescription: String?
    @NSManaged var coverImage: Data?
    
    // Reading Information
    @NSManaged var readState: BookReadState
    @NSManaged var startedReading: Date?
    @NSManaged var finishedReading: Date?

    // Other Metadata
    @NSManaged var notes: String?
    @NSManaged var currentPage: NSNumber?
    @NSManaged var sort: NSNumber?
    @NSManaged var createdWhen: Date
    
    // Relationships
    @NSManaged var subjects: NSOrderedSet
    @NSManaged var authors: NSOrderedSet
    
    var subjectsArray: [Subject] {
        get { return subjects.array.map{($0 as! Subject)} }
    }
    
    var authorsArray: [Author] {
        get { return authors.array.map{($0 as! Author)} }
    }
    
    var authorList: String {
        get {
            return authorsArray.map{($0.firstNames == nil ? "" : ($0.firstNames! + " ")) + $0.lastName}.joined(separator: ", ")
        }
    }

/*
    These functions might be useful but don't work on iOS 9
    See https://stackoverflow.com/q/7385439/5513562

    @objc(addSubjects:)
    @NSManaged public func addSubjects(_ values: NSOrderedSet)
    
    @objc(removeSubjects:)
    @NSManaged public func removeSubjects(_ values: NSSet)
*/

}

@objc(Subject)
public class Subject: NSManagedObject {
    @NSManaged public var name: String
    @NSManaged public var books: NSSet
    
    override public func willSave() {
        super.willSave()
        if !isDeleted && books.count == 0 {
            managedObjectContext?.delete(self)
        }
    }
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

    func populate(from readingInformation: BookReadingInformation) {
        readState = readingInformation.readState
        startedReading = readingInformation.startedReading
        finishedReading = readingInformation.finishedReading
        currentPage = readingInformation.currentPage == nil ? nil : NSNumber(integerLiteral: readingInformation.currentPage!)
    }
    
    func toSpotlightItem() -> SpotlightItem {
        let spotlightTitle = "\(title) - \(authorList)"
        
        return SpotlightItem(uniqueIdentifier: objectID.uriRepresentation().absoluteString, title: spotlightTitle, description: bookDescription, thumbnailImageData: coverImage)
    }
    
    static let transistionToReadingStateAction = GeneralUIAction<Book>(style: .normal, title: "Start") { book in
        let reading = BookReadingInformation(readState: .reading, startedWhen: Date(), finishedWhen: nil, currentPage: nil)
        updateReadStateAndLog(book: book, readingInformation: reading)
    }
    
    static let transistionToFinishedStateAction = GeneralUIAction<Book>(style: .normal, title: "Finish") { book in
        let finished = BookReadingInformation(readState: .finished, startedWhen: book.startedReading!, finishedWhen: Date(), currentPage: nil)
        updateReadStateAndLog(book: book, readingInformation: finished)
    }
    
    private static func updateReadStateAndLog(book: Book, readingInformation: BookReadingInformation) {
        appDelegate.booksStore.update(book: book, withReadingInformation: readingInformation)
        UserEngagement.logEvent(.transitionReadState)
        UserEngagement.onReviewTrigger()
    }
    
    static let deleteAction = GeneralUIAction<Book>(style: .destructive, title: "Delete") { book in
        appDelegate.booksStore.deleteBook(book)
        UserEngagement.logEvent(.deleteBook)
    }
    
    static let csvExport = CsvExport<Book>(columns:
        CsvColumn<Book>(header: "ISBN-13", cellValue: {$0.isbn13}),
        CsvColumn<Book>(header: "Google Books ID", cellValue: {$0.googleBooksId}),
        CsvColumn<Book>(header: "Title", cellValue: {$0.title}),
        CsvColumn<Book>(header: "Author", cellValue: {$0.authorList}),
        CsvColumn<Book>(header: "Page Count", cellValue: {$0.pageCount == nil ? nil : String(describing: $0.pageCount!)}),
        CsvColumn<Book>(header: "Publication Date", cellValue: {$0.publicationDate == nil ? nil : $0.publicationDate!.toString(withDateFormat: "yyyy-MM-dd")}),
        CsvColumn<Book>(header: "Description", cellValue: {$0.bookDescription}),
        CsvColumn<Book>(header: "Subjects", cellValue: {$0.subjectsArray.map{$0.name}.joined(separator: "; ")}),
        CsvColumn<Book>(header: "Started Reading", cellValue: {$0.startedReading?.toString(withDateFormat: "yyyy-MM-dd")}),
        CsvColumn<Book>(header: "Finished Reading", cellValue: {$0.finishedReading?.toString(withDateFormat: "yyyy-MM-dd")}),
        CsvColumn<Book>(header: "Current Page", cellValue: {$0.currentPage == nil ? nil : String(describing: $0.currentPage!)}),
        CsvColumn<Book>(header: "Notes", cellValue: {$0.notes})
    )
    
    static let csvColumnHeaders = ["Google Books ID", "ISBN-13", "Title", "Author", "Page Count", "Publication Date", "Description", "Subjects", "Started Reading", "Finished Reading", "Current Page", "Notes"]
}


/// A mutable, non-persistent representation of the metadata fields of a Book object.
/// Useful for maintaining in-creation books, or books being edited.
class BookMetadata {
    let googleBooksId: String?
    var title: String?
    var authors = [(firstNames: String?, lastName: String)]()
    var authorList: String {
        get {
            return authors.map{($0.0 == nil ? "" : ($0.0! + " ")) + $0.1}.joined(separator: " ")
        }
    }
    var pageCount: Int?
    var publicationDate: Date?
    var bookDescription: String?
    var isbn13: String?
    var coverImage: Data?
    var subjects = [String]()
    
    // ONLY used for import; not a usually populated field
    var coverUrl: URL?
    
    init(googleBooksId: String? = nil) {
        self.googleBooksId = googleBooksId
    }
    
    func isValid() -> Bool {
        return title?.isEmptyOrWhitespace == false && authors.count >= 1
    }
    
    init(book: Book) {
        self.title = book.title
        self.authors = book.authors.map{
            let author = $0 as! Author
            return (author.firstNames, author.lastName)
        }
        self.bookDescription = book.bookDescription
        self.pageCount = book.pageCount as? Int
        self.publicationDate = book.publicationDate
        self.coverImage = book.coverImage
        self.isbn13 = book.isbn13
        self.googleBooksId = book.googleBooksId
        self.subjects = book.subjects.map{($0 as! Subject).name}
    }
    
    static func csvImport(csvData: [String: String]) -> (BookMetadata, BookReadingInformation, String?) {
        
        let bookMetadata = BookMetadata(googleBooksId: csvData["Google Books ID"]?.nilIfWhitespace())
        bookMetadata.title = csvData["Title"]?.nilIfWhitespace()
        //bookMetadata.authors = csvData["Author"]?.nilIfWhitespace()
        bookMetadata.isbn13 = Isbn13.tryParse(inputString: csvData["ISBN-13"])
        bookMetadata.pageCount = csvData["Page Count"] == nil ? nil : Int(csvData["Page Count"]!)
        bookMetadata.publicationDate = csvData["Publication Date"] == nil ? nil : Date(dateString: csvData["Publication Date"]!)
        bookMetadata.bookDescription = csvData["Description"]?.nilIfWhitespace()
        bookMetadata.subjects = csvData["Subjects"]?.components(separatedBy: ";").flatMap{$0.trimming().nilIfWhitespace()} ?? []
        bookMetadata.coverUrl = URL(optionalString: csvData["Cover URL"])
        
        let startedReading = Date(dateString: csvData["Started Reading"])
        let finishedReading = Date(dateString: csvData["Finished Reading"])
        let currentPage = csvData["Current Page"] == nil ? nil : Int(string: csvData["Current Page"]!)

        let readingInformation: BookReadingInformation
        if startedReading != nil && finishedReading != nil {
            readingInformation = BookReadingInformation.finished(started: startedReading!, finished: finishedReading!)
        }
        else if startedReading != nil && finishedReading == nil {
            readingInformation = BookReadingInformation.reading(started: startedReading!, currentPage: currentPage)
        }
        else {
            readingInformation = BookReadingInformation.toRead()
        }
        
        let notes = csvData["Notes"]?.isEmptyOrWhitespace == false ? csvData["Notes"] : nil
        return (bookMetadata, readingInformation, notes)
    }
}

/// A mutable, non-persistent representation of a the reading status of a Book object.
/// Useful for maintaining in-creation books, or books being edited.
class BookReadingInformation {
    // TODO: consider create class heirachy with non-optional Dates where appropriate
    
    let readState: BookReadState
    let startedReading: Date?
    let finishedReading: Date?
    let currentPage: Int?
    
    /// Will only populate the start date if started; will only populate the finished date if finished.
    /// Otherwise, dates are set to nil.
    init(readState: BookReadState, startedWhen: Date?, finishedWhen: Date?, currentPage: Int?) {
        self.readState = readState
        switch readState {
        case .toRead:
            self.startedReading = nil
            self.finishedReading = nil
            self.currentPage = nil
        case .reading:
            self.startedReading = startedWhen!
            self.finishedReading = nil
            self.currentPage = currentPage
        case .finished:
            self.startedReading = startedWhen!
            self.finishedReading = finishedWhen!
            self.currentPage = nil
        }
    }
    
    static func toRead() -> BookReadingInformation {
        return BookReadingInformation(readState: .toRead, startedWhen: nil, finishedWhen: nil, currentPage: nil)
    }
    
    static func reading(started: Date, currentPage: Int?) -> BookReadingInformation {
        return BookReadingInformation(readState: .reading, startedWhen: started, finishedWhen: nil, currentPage: currentPage)
    }
    
    static func finished(started: Date, finished: Date) -> BookReadingInformation {
        return BookReadingInformation(readState: .finished, startedWhen: started, finishedWhen: finished, currentPage: nil)
    }
}


