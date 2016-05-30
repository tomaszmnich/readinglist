//
//  NSDateExtensions.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

extension NSDate {
    convenience init(dateString: String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let date = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval: 0, sinceDate: date)
    }
}

extension CollectionType {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension String {
    /// Return whether the string contains any characters which are not whitespace.
    func isEmptyOrWhitespace() -> Bool {
        return self.trim().isEmpty
    }
    
    /// Removes all whitespace characters from the beginning and the end of the string.
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}

extension NSPredicate {
    @nonobjc static var TruePredicate = NSPredicate(format: "TRUEPREDICATE")
    
    convenience init(fieldName: String, equalTo: String) {
        self.init(format: "\(fieldName) == \(equalTo)")
    }
    
    convenience init(fieldName: String, containsSubstring: String) {
        self.init(format: "\(fieldName) CONTAINS[cd] \(containsSubstring)")
    }
}