//
//  NSDateExtensions.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(fromHex: UInt32){
        self.init(colorLiteralRed: Float(((fromHex & 0xFF0000) >> 16))/255.0, green: Float(((fromHex & 0x00FF00) >> 8))/255.0, blue: Float(((fromHex & 0x0000FF) >> 0))/255.0, alpha: 1.0)
    }
}

extension Date {
    init(dateString: String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = dateStringFormatter.date(from: dateString)!
        self.init(timeInterval: 0, since: date)
    }
    
    func toString(withDateStyle dateStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func toString(withDateFormat dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }
    
    func toHumanisedString() -> String {
        let today = Date()
        
        // If we are in the future, fully specify the date
        if (self as NSDate).laterDate(today) == self {
            return self.toString(withDateFormat: "d MMM yyyy")
        }
        
        // Otherwise split the dates into components
        let theseComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: self)
        let todayComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: today)
        
        
        // more than 5 days ago
        if theseComponents.year! != todayComponents.year! || todayComponents.month! != theseComponents.month! || todayComponents.day! - theseComponents.day! >= 5 {
            return self.toString(withDateFormat: "d MMM yyyy")
        }
        else if todayComponents.day! - theseComponents.day! >= 2 {
            // between 2 and 5 days ago
            return self.toString(withDateFormat: "EEEE")
        }
        else if todayComponents.day! - theseComponents.day! == 1 {
            return "Yesterday"
        }
        else {
            return "Today"
        }
    }
}

extension UIImage {
    convenience init?(optionalData: Data?) {
        if let data = optionalData {
            self.init(data: data)
        }
        else {
            return nil
        }
    }
}

extension CharacterSet {
    static func nonAlphanumeric() -> CharacterSet {
        return CharacterSet.alphanumerics.inverted
    }
}

extension String {
    /// Return whether the string contains any characters which are not whitespace.
    func isEmptyOrWhitespace() -> Bool {
        return self.trim().isEmpty
    }
    
    /// Removes all whitespace characters from the beginning and the end of the string.
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func toAttributedString(_ attributes: [String : AnyObject]?) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: attributes)
    }
    
    func toAttributedStringWithFont(_ font: UIFont) -> NSAttributedString {
        return self.toAttributedString([NSFontAttributeName: font])
    }
    
    func withTextStyle(_ textStyle: UIFontTextStyle) -> NSAttributedString {
        return self.toAttributedStringWithFont(UIFont.preferredFont(forTextStyle: textStyle))
    }
    
    func toDateViaFormat(_ format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: self)
    }
}

extension NSMutableAttributedString {
    
    static func byConcatenating(withNewline: Bool, _ attributedStrings: NSAttributedString?...) -> NSMutableAttributedString? {
        // First of all, filter out all of the nil strings
        let notNilStrings = attributedStrings.flatMap{$0}
        
        // Check that there is a first string in the array; if not, return nil
        guard notNilStrings.count > 0 else { return nil }
        let firstString = notNilStrings[0]
        
        // Initialise the mutable string with the first string
        let mutableAttributedString = NSMutableAttributedString(attributedString: firstString)
        
        // For all of the other strings (if there are any), append them to the mutable strings
        for attrString in notNilStrings.dropFirst() {
            if withNewline {
                mutableAttributedString.appendNewline()
            }
            mutableAttributedString.append(attrString)
        }
        
        return mutableAttributedString
    }
    
    func appendNewline() {
        self.append(NSAttributedString(string: "\u{2028}"))
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
    
    static func Or(_ orPredicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
    }
    
    static func And(_ andPredicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
    }
    
    static func searchWithinFields(_ searchString: String, fieldNames: String...) -> NSPredicate {
        // Split on whitespace and remove empty elements
        let searchStringComponents = searchString.components(separatedBy: CharacterSet.nonAlphanumeric()).filter{
            !$0.isEmpty
        }
        
        // AND each component, where each component is OR'd over each of the fields
        return NSPredicate.And(searchStringComponents.map{ searchStringComponent in
            NSPredicate.Or(fieldNames.map{ fieldName in
                NSPredicate(fieldName: fieldName, containsSubstring: searchStringComponent)
            })
        })
    }
    
    
    func Or(_ orPredicate: NSPredicate) -> NSPredicate {
        return NSPredicate.Or([self, orPredicate])
    }
    
    
    func And(_ andPredicate: NSPredicate) -> NSPredicate {
        return NSPredicate.And([self, andPredicate])
    }
}
