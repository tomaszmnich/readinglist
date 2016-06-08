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
    // Book Metadata
    @NSManaged private(set) var title: String
    @NSManaged private(set) var subtitle: String?
    @NSManaged private(set) var authorList: String?
    @NSManaged private(set) var isbn13: String?
    @NSManaged private(set) var pageCount: NSNumber?
    @NSManaged private(set) var publishedDate: NSDate?
    @NSManaged private(set) var bookDescription: String?
    @NSManaged private(set) var coverImage: NSData?
    
    // Reading Information
    @NSManaged private(set) var readState: BookReadState
    @NSManaged private(set) var startedReading: NSDate?
    @NSManaged private(set) var finishedReading: NSDate?
    
    // Other Metadata
    @NSManaged var sort: NSNumber?
    
    func Populate(metadata: BookMetadata) {
        title = metadata.title
        authorList = metadata.authorList
        isbn13 = metadata.isbn13
        pageCount = metadata.pageCount
        publishedDate = metadata.publishedDate
        bookDescription = metadata.bookDescription
        coverImage = metadata.coverImage
    }
    
    func Populate(readingInformation: BookReadingInformation) {
        readState = readingInformation.readState
        startedReading = readingInformation.startedReading
        finishedReading = readingInformation.finishedReading
        // Wipe out the sort if we have moved out of this section
        if readState != .ToRead {
            sort = nil
        }
    }
}



/// A mutable, non-persistent representation of a Book object.
/// Useful for maintaining in-creation books, or books being edited.
class BookMetadata {
    var title: String!
    var subtitle: String?
    var isbn13: String?
    var authorList: String?
    var pageCount: Int?
    var publishedDate: NSDate?
    var bookDescription: String?
    var coverUrl: String?
    var coverImage: NSData?
}

class BookReadingInformation {
    var readState: BookReadState!
    var startedReading: NSDate?
    var finishedReading: NSDate?
}

/// The availale reading progress states
@objc enum BookReadState : Int32, CustomStringConvertible {
    case Reading = 1
    case ToRead = 2
    case Finished = 3
    
    var description: String {
        switch self{
        case .Reading:
            return "Reading"
        case .ToRead:
            return "To Read"
        case .Finished:
            return "Finished"
        }
    }
}