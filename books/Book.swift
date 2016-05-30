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
    @NSManaged var title: String
    @NSManaged var subtitle: String?
    @NSManaged var authorList: String?
    @NSManaged var isbn13: String?
    @NSManaged var pageCount: NSNumber?
    @NSManaged var publishedDate: NSDate?
    @NSManaged var bookDescription: String? // 'description' would be a better name but the data model does not support using that term for an attribute
    @NSManaged var coverImage: NSData?
    @NSManaged var readState: BookReadState
    
    @NSManaged var startedReading: NSDate?
    @NSManaged var finishedReading: NSDate?
    
    func Populate(metadata: BookMetadata, readingInformation: BookReadingInformation) {
        title = metadata.title
        authorList = metadata.authorList
        isbn13 = metadata.isbn13
        pageCount = metadata.pageCount
        publishedDate = metadata.publishedDate
        bookDescription = metadata.bookDescription
        coverImage = metadata.coverImage
        readState = readingInformation.readState
        startedReading = readingInformation.startedReading
        finishedReading = readingInformation.finishedReading
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