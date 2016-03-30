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
    @NSManaged var isbn13: String
    @NSManaged var title: String
    @NSManaged var authorList: String?
    @NSManaged var pageCount: NSNumber?
    @NSManaged var publisher: String?
    @NSManaged var publishedDate: String?
    // 'description' would be a better name but the data model does not support using that term for an attribute
    @NSManaged var bookDescription: String?
    @NSManaged var startedReading: NSDate?
    @NSManaged var finishedReading: NSDate?
    var coverUrl: String?
    @NSManaged var coverImage: NSData?
    @NSManaged var readState: BookReadState
}

/// The availale reading progress states
@objc enum BookReadState : Int32 {
    case Reading = 1
    case ToRead = 2
    case Finished = 3
}