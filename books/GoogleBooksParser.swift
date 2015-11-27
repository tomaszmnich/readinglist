//
//  GoogleBooksParser.swift
//  books
//
//  Created by Andrew Bennet on 25/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import SwiftyJSON

/// Deals with parsing the JSON returned by GoogleBook's API into object representations.
class GoogleBooksParser {
    
    /// Parses a JSON GoogleBooks response and returns the corresponding ParsedBookResult.
    static func parseJsonResponse(jResponse: JSON) -> BookMetadata {
        // Prepare the result
        let result = BookMetadata()
        
        // The information we seek is in the volumneInfo element. FOr ow
        let volumeInfo = jResponse["items"][0]["volumeInfo"]
        
        // Add the title
        result.title = volumeInfo["title"].string

        // Add all the authors
        let authors = volumeInfo["authors"]
        for author in authors{
            result.authors.append(author.0)
        }
        
        // Add a link at which a front cover image can be found
        result.imageURL = volumeInfo["imageLinks"]["thumbnail"].string//?.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        return result
    }
}

/// Holds metadata about a book. Merely a holding bay.
class BookMetadata : CustomStringConvertible {
    var title: String?
    var authors = [String]()
    var imageURL: String?
    var imageData: NSData?
    var isbn13: String?
    
    var description: String {
        return "Title: \(title); Authors: \(authors); ImageURL: \(imageURL); ISBN-13: \(isbn13)"
    }
}