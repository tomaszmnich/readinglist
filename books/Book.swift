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
    @NSManaged var authorList: String?
    @NSManaged var isbn13: String?
    @NSManaged var pageCount: NSNumber?
    @NSManaged var publishedDate: String?
    @NSManaged var bookDescription: String? // 'description' would be a better name but the data model does not support using that term for an attribute
    @NSManaged var coverImage: NSData?
    @NSManaged var readState: BookReadState
    
    @NSManaged var startedReading: NSDate?
    @NSManaged var finishedReading: NSDate?
    
    var coverUrl: String?
    
    func UpdateFromMetadata(metadata: BookMetadata){
        title = metadata.title
        readState = metadata.readState
        authorList = metadata.authorList
        isbn13 = metadata.isbn13
        pageCount = metadata.pageCount
        publishedDate = metadata.publishedDate
        bookDescription = metadata.bookDescription
        startedReading = metadata.startedReading
        finishedReading = metadata.finishedReading
        coverImage = metadata.coverImage
    }
}

/// A mutable, non-persistent representation of a Book object.
/// Useful for maintaining in-creation books, or books being edited.
class BookMetadata {
    var title: String!
    var readState: BookReadState!
    
    var isbn13: String?
    var authorList: String?
    var pageCount: NSNumber?
    var publishedDate: String?
    var bookDescription: String?
    var startedReading: NSDate?
    var finishedReading: NSDate?
    var coverUrl: String?
    var coverImage: NSData?
}


/// The availale reading progress states
@objc enum BookReadState : Int32 {
    case Reading = 1
    case ToRead = 2
    case Finished = 3
}