//
//  NSDateExtensions.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

extension NSDate {
    convenience init(dateString: String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let date = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval: 0, sinceDate: date)
    }
    
    func toString(withDateStyle dateStyle: NSDateFormatterStyle) -> String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .NoStyle
        return formatter.stringFromDate(self)
    }
    
    func toString(withDateFormat dateFormat: String) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.stringFromDate(self)
    }
    
    func toHumanisedString() -> String {
        let today = NSDate()
        
        // If we are in the future, fully specify the date
        if self.laterDate(today) == self {
            return self.toString(withDateFormat: "d MMM yyyy")
        }
        
        // Otherwise split the dates into components
        let theseComponents = NSCalendar.currentCalendar().components([.Day, .Month, .Year], fromDate: self)
        let todayComponents = NSCalendar.currentCalendar().components([.Day, .Month, .Year], fromDate: today)
        
        
        // more than 5 days ago
        if theseComponents.year != todayComponents.year || todayComponents.month != theseComponents.month || todayComponents.day - theseComponents.day >= 5 {
            return self.toString(withDateFormat: "d MMM yyyy")
        }
        else if todayComponents.day - theseComponents.day >= 2 {
            // between 2 and 5 days ago
            return self.toString(withDateFormat: "EEEE")
        }
        else if todayComponents.day - theseComponents.day == 1 {
            return "Yesterday"
        }
        else {
            return "Today"
        }
    }
}

extension CollectionType {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIImage {
    convenience init?(optionalData: NSData?) {
        if let data = optionalData {
            self.init(data: data)
        }
        else {
            return nil
        }
    }
}

extension NSCharacterSet {
    static func nonAlphanumeric() -> NSCharacterSet {
        return NSCharacterSet.alphanumericCharacterSet().invertedSet
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
    
    func toAttributedString(attributes: [String : AnyObject]?) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: attributes)
    }
    
    func toAttributedStringWithFont(font: UIFont) -> NSAttributedString {
        return self.toAttributedString([NSFontAttributeName: font])
    }
    
    func withTextStyle(textStyle: String) -> NSAttributedString {
        return self.toAttributedStringWithFont(UIFont.preferredFontForTextStyle(textStyle))
    }
    
    func toDateViaFormat(format: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = NSLocale.currentLocale()
        return dateFormatter.dateFromString(self)
    }
}

extension NSMutableAttributedString {
    
    static func byConcatenating(withNewline withNewline: Bool, _ attributedStrings: NSAttributedString?...) -> NSMutableAttributedString? {
        // First of all, filter out all of the nil strings
        let notNilStrings = attributedStrings.flatMap{$0}
        
        // Check that there is a first string in the array; if not, return nil
        guard let firstString = notNilStrings[safe: 0] else { return nil }
        
        // Initialise the mutable string with the first string
        let mutableAttributedString = NSMutableAttributedString(attributedString: firstString)
        
        // For all of the other strings (if there are any), append them to the mutable strings
        for attrString in notNilStrings.dropFirst() {
            if withNewline {
                mutableAttributedString.appendNewline()
            }
            mutableAttributedString.appendAttributedString(attrString)
        }
        
        return mutableAttributedString
    }
    
    func appendNewline() {
        self.appendAttributedString(NSAttributedString(string: "\u{2028}"))
    }
}

extension NSPredicate {    
    
    convenience init(fieldName: String, equalToInt: Int) {
        self.init(format: "\(fieldName) == %d", equalToInt)
    }
    
    convenience init(fieldName: String, containsSubstring: String) {
        // Special case for "contains empty string": should return TRUE
        if containsSubstring.isEmpty {
            self.init(format: "TRUEPREDICATE")
        }
        else {
            self.init(format: "\(fieldName) CONTAINS[cd] %@", containsSubstring)
        }
    }
    
    static func Or(orPredicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
    }
    
    static func And(andPredicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
    }
    
    static func searchWithinFields(searchString: String, fieldNames: String...) -> NSPredicate {
        // Split on whitespace and remove empty elements
        let searchStringComponents = searchString.componentsSeparatedByCharactersInSet(NSCharacterSet.nonAlphanumeric()).filter{
            !$0.isEmpty
        }
        
        // AND each component, where each component is OR'd over each of the fields
        return NSPredicate.And(searchStringComponents.map{ searchStringComponent in
            NSPredicate.Or(fieldNames.map{ fieldName in
                NSPredicate(fieldName: fieldName, containsSubstring: searchStringComponent)
            })
        })
    }
    
    @warn_unused_result
    func Or(orPredicate: NSPredicate) -> NSPredicate {
        return NSPredicate.Or([self, orPredicate])
    }
    
    @warn_unused_result
    func And(andPredicate: NSPredicate) -> NSPredicate {
        return NSPredicate.And([self, andPredicate])
    }
}