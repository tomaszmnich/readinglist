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
    // Book properties
    @NSManaged var isbn13: String?
    @NSManaged var title: String
    @NSManaged var pageCount: NSNumber?
    @NSManaged var publisher: String?
    @NSManaged var publishedDate: String?
    
    // Holds a set of Author objects
    @NSManaged var authoredBy: NSOrderedSet?
    
    // Image data of the book cover
    @NSManaged var coverImage: NSData?

    // Internal state managers
    @NSManaged var source: BookSource
    @NSManaged var sourceId: String!
    @NSManaged var globalId: String!
    @NSManaged var readState: BookReadState
    
    /// Builds a string consisting of a comma separated list of the authors
    var authorListString: String?{
        var authorListString = String()
        if let authors = authoredBy?.array as? [Author] {
        for author in authors{
            if authors.indexOf(author) != 0{
                authorListString += ", "
            }
            authorListString += author.name!
            }
        }
        return authorListString
    }
    
    /** 
     Populates properties on this Book from the supplied BookMetadata.
     Does not populate Author objects - these must be done separately.
    */
    func Populate(metadata: BookMetadata){
        source = metadata.source
        isbn13 = metadata.isbn13
        readState = metadata.readState
        switch source{
        case BookSource.Manual:
            sourceId = NSUUID().UUIDString
        default:
            sourceId = isbn13
        }
        title = metadata.title!
        if metadata.pageCount != nil{
            pageCount = NSNumber(int: Int32(metadata.pageCount!))
        }
        publisher = metadata.publisher
        publishedDate = metadata.publishedDate
        
        coverImage = metadata.imageData
        
        globalId = "\(source.rawValue):\(sourceId)"
    }
}

@objc(Author)
class Author: NSManagedObject{
    @NSManaged var name: String!
    @NSManaged var authorOf: Book
}

/// The availale reading progress states
@objc enum BookReadState : Int32 {
    case Reading = 1
    case ToRead = 2
    case Finished = 3
}

/// The source of the information for a Book
@objc enum BookSource: Int32 {
    case Manual = 1
    case GoogleBooks = 2
    case OpenLibrary = 3
}

/// Holds metadata about a book. Merely a holding bay.
class BookMetadata : CustomStringConvertible {

    init(bookSource: BookSource){
        source = bookSource
    }
    
    // temporarily always set
    var readState = BookReadState.Reading
    var source: BookSource!
    var isbn13: String?
    var title: String!
    var authors = [String]()
    var publishedDate: String?
    var publisher: String?
    var pageCount: Int?
    var imageURL: String?
    var imageData: NSData?
    
    var description: String {
        return title
    }
}