//
//  BookPredicate.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class BookPredicate {
    
    static let titleFieldName = "title"
    static let authorFieldName = "authorList"
    static let readStateFieldName = "readState"
    
    static func readStateEqual(readState: BookReadState) -> NSPredicate {
        return NSPredicate(fieldName: readStateFieldName, equalToInt: Int(readState.rawValue))
    }
    
    static func searchInTitleOrAuthor(searchString: String) -> NSPredicate {
        return NSPredicate.searchWithinFields(searchString, fieldNames: titleFieldName, authorFieldName)
    }
    
    static func titleSort(ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: titleFieldName, ascending: ascending)
    }
    
    static func readStateSort(ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: readStateFieldName, ascending: ascending)
    }
}