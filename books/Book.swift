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
    @NSManaged var title: String?
    @NSManaged var author: String?
    @NSManaged var isbn13: String?
    @NSManaged var coverImage: NSData?
    
    func PopulateFromParsedResult(parsedResult: ParsedBookResult){
        title = parsedResult.title
        author = parsedResult.authors.first //for now
        coverImage = parsedResult.imageData
        isbn13 = parsedResult.isbn13
    }
}