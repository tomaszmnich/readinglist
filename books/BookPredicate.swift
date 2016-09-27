//
//  BookPredicate.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class BookPredicate {
    
    fileprivate static let titleFieldName = "title"
    fileprivate static let authorFieldName = "authorList"
    fileprivate static let sortFieldName = "sort"
    fileprivate static let startedReadingFieldName = "startedReading"
    fileprivate static let finishedReadingFieldName = "finishedReading"
    
    static let readStateFieldName = "readState"
    
    static func readStateEqual(_ readState: BookReadState) -> NSPredicate {
        return NSPredicate(fieldName: readStateFieldName, equalToInt: Int(readState.rawValue))
    }
    
    static func searchInTitleOrAuthor(_ searchString: String) -> NSPredicate {
        return NSPredicate.searchWithinFields(searchString, fieldNames: titleFieldName, authorFieldName)
    }
    
    static let titleSort = NSSortDescriptor(key: titleFieldName, ascending: true)
    static let startedReadingSort = NSSortDescriptor(key: startedReadingFieldName, ascending: true)
    static let finishedReadingSort = NSSortDescriptor(key: finishedReadingFieldName, ascending: true)
    static let readStateSort = NSSortDescriptor(key: readStateFieldName, ascending: true)
    static let sortIndexSort = NSSortDescriptor(key: sortFieldName, ascending: true)
}
