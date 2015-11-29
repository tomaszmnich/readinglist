//
//  book.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData

@objc enum BookReadState : Int32 {
    case Finished = -1
    case Reading = 0
    case ToRead = 1
}

@objc(Book)
class Book: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var isbn13: String?
    @NSManaged var coverImage: NSData?
    @NSManaged var readState: BookReadState
    @NSManaged var authoredBy: NSOrderedSet?
    
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
    
    func PopulateFromParsedResult(parsedResult: BookMetadata){
        title = parsedResult.title
        coverImage = parsedResult.imageData
        isbn13 = parsedResult.isbn13
    }
}

@objc(Author)
class Author: NSManagedObject{
    @NSManaged var name: String!
    @NSManaged var authorOf: Book
}