//
//  BookPredicateBuilder.swift
//  books
//
//  Created by Andrew Bennet on 15/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class BookPredicateBuilder : SearchPredicateBuilder {
    init(readStatePredicate: NSPredicate){
        self.readStatePredicate = readStatePredicate
    }
    
    let readStatePredicate: NSPredicate
    
    func buildPredicateFrom(searchText: String?) -> NSPredicate {
        var predicate = readStatePredicate
        if let searchText = searchText,
            !searchText.isEmptyOrWhitespace && searchText.trimming().characters.count >= 2 {
            predicate = readStatePredicate.And(BookPredicate.search(searchString: searchText))
        }
        return predicate
    }
}
