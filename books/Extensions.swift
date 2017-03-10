//
//  NSDateExtensions.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

extension UIColor {
    convenience init(fromHex: UInt32){
        self.init(colorLiteralRed: Float(((fromHex & 0xFF0000) >> 16))/255.0, green: Float(((fromHex & 0x00FF00) >> 8))/255.0, blue: Float(((fromHex & 0x0000FF) >> 0))/255.0, alpha: 1.0)
    }
}

public extension Date {
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
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = Calendar.current.startOfDay(for: self)
        let date2 = Calendar.current.startOfDay(for: today)
        
        let daysBetween = Calendar.current.dateComponents([.day], from: date1, to: date2).day!
        
        if daysBetween < 0 {
            return self.toString(withDateFormat: "d MMM")
        }
        if daysBetween == 0 {
            return "Today"
        }
        if daysBetween > 0 && daysBetween <= 5 {
            return self.toString(withDateFormat: "EEE")
        }
        else {
            return self.toString(withDateFormat: "d MMM")
        }
    }
    
    func date(byAdding dateComponents: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: dateComponents, to: self)
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

extension JSON {
    init?(optionalData: Data?) {
        if let data = optionalData {
            self.init(data: data)
        }
        else {
            return nil
        }
    }
}

extension String {
    /// Return whether the string contains any characters which are not whitespace.
    var isEmptyOrWhitespace: Bool {
        return self.trimming().isEmpty
    }
    
    /// Removes all whitespace characters from the beginning and the end of the string.
    func trimming() -> String {
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

extension NSPredicate {    
    
    convenience init(boolean: Bool) {
        switch boolean {
        case true:
            self.init(format: "TRUEPREDICATE")
        case false:
            self.init(format: "FALSEPREDICATE")
        }
    }
    
    convenience init(fieldName: String, equalToInt: Int) {
        self.init(format: "\(fieldName) == %d", equalToInt)
    }
    
    convenience init(fieldName: String, containsSubstring: String) {
        // Special case for "contains empty string": should return TRUE
        if containsSubstring.isEmpty {
            self.init(boolean: true)
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
        let searchStringComponents = searchString.components(separatedBy: CharacterSet.alphanumerics.inverted).filter{
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
