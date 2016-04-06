//
//  BookFilterPredicate.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

// Field and Entity name string constants are held here.
private let titleFieldName = "title"
private let readStateFieldName = "readState"

protocol BookFilter{
    func ToPredicate() -> NSPredicate
}

enum ComparisonType{
    case Equals
    case Contains
}

class TitleFilter: BookFilter {
    var titleText: String!
    var comparisonType: ComparisonType!
    
    init(comparison: ComparisonType, text: String){
        comparisonType = comparison
        titleText = text
    }
    
    func ToPredicate() -> NSPredicate {
        // Special case for "contains empty string": should return TRUE
        if comparisonType == .Contains && titleText.isEmpty{
            return NSPredicate(format: "TRUEPREDICATE")
        }
        return NSPredicate(format: "\(titleFieldName) \(comparisonType == .Equals ? "==" : "CONTAINS[cd]") \"\(titleText)\"")
    }
}

class ReadStateFilter: BookFilter{
    var readStates: [BookReadState]!
    
    init(states: [BookReadState]){
        readStates = states
    }
    
    func ToPredicate() -> NSPredicate{
        return NSPredicate(format: readStates.map{"(\(readStateFieldName) == \($0.rawValue))"}.joinWithSeparator(" OR "))
    }
}

enum BookSortOrder {
    case Title
    
    var fieldName: String{
        switch self{
        case .Title:
            return titleFieldName
        }
    }
    
    func ToSortDescriptor() -> NSSortDescriptor{
        return NSSortDescriptor(key: fieldName, ascending: true)
    }
}
