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

public extension NSAttributedString {
    public convenience init(string: String, withFont font: UIFont) {
        self.init(string: string, attributes: [NSFontAttributeName: font])
    }
}

extension UIApplication {
    func openUrlPlatformSpecific(url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: completionHandler)
        }
        else {
            let result = UIApplication.shared.openURL(url)
            completionHandler?(result)
        }
    }
}

extension NSMutableAttributedString {
    
    @discardableResult func hyperlinkText(_ textToLink: String, to linkURL: URL) -> Bool {
        let foundRange = self.mutableString.range(of: textToLink)
        if foundRange.location != NSNotFound {
            self.addAttribute(NSLinkAttributeName, value: linkURL, range: foundRange)
            return true
        }
        return false
    }

    func chainAppend(string: String, withFont font: UIFont) -> NSMutableAttributedString {
        self.append(NSAttributedString(string: string, withFont: font))
        return self
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
    
    static func startOfToday() -> Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func compareIgnoringTime(_ other: Date) -> ComparisonResult {
        return self.startOfDay().compare(other.startOfDay())
    }
    
    func toShortPrettyString() -> String {
        let today = Date.startOfToday()
        let otherDate = startOfDay()
        
        let thisYear = Calendar.current.dateComponents([.year], from: today).year!
        let otherYear = Calendar.current.dateComponents([.year], from: otherDate).year!
        
        let daysDifference = Calendar.current.dateComponents([.day], from: otherDate, to: today).day!
        
        if daysDifference == 0 {
            return "Today"
        }
        if daysDifference > 0 && daysDifference <= 5 {
            return self.toString(withDateFormat: "EEE")
        }
        else {
            // Use the format "12 Feb", or - if the date is not from this year - "12 Feb 2015"
            return self.toString(withDateFormat: "d MMM\(thisYear == otherYear ? "" : " yyyy")")
        }
    }
    
    func date(byAdding dateComponents: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: dateComponents, to: self)
    }
}

extension NSData {
    static func fromMainBundle(resource: String, type: String) -> NSData {
        let path = Bundle.main.path(forResource: resource, ofType: type)!
        return try! NSData(contentsOfFile: path)
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
    
    convenience init(fieldName: String, equalTo: Int) {
        self.init(format: "\(fieldName) == %d", equalTo)
    }
    
    convenience init(fieldName: String, equalToText: String) {
        self.init(format: "\(fieldName) == %@", equalToText)
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
