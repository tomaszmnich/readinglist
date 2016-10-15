//
//  BookPredicateBuilder.swift
//  books
//
//  Created by Andrew Bennet on 15/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class BookPredicateBuilder : SearchPredicateBuilder {
    init(selectedSegment: @escaping (() -> TableSegmentOption)){
        selectedSegmentFunc = selectedSegment
    }
    
    let selectedSegmentFunc: (() -> TableSegmentOption)
    
    func buildPredicateFrom(searchText: String?) -> NSPredicate {
        var predicate = self.selectedSegmentFunc().toPredicate()
        if let searchText = searchText,
            searchText.isEmptyOrWhitespace() && searchText.trim().characters.count >= 2 {
            predicate = predicate.And(BookPredicate.titleAndAuthor(searchString: searchText))
        }
        return predicate
    }
}
