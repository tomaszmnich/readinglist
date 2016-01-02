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
    static func parseJsonResponse(isbn13: String, jResponse: JSON) -> BookMetadata? {
        // Prepare the result
        let result = BookMetadata()
        
        // The information we seek is in the volumneInfo element. FOr ow
        let volumeInfo = jResponse["items"][0]["volumeInfo"]

        // Add all the authors
        volumeInfo["authors"].forEach{result.authors.append($1.rawString()!)}
        result.title = volumeInfo["title"].string
        result.isbn13 = isbn13
        result.publishedDate = volumeInfo["publishedDate"].string
        result.publisher = volumeInfo["publisher"].string
        result.pageCount = volumeInfo["pageCount"].int
        result.bookDescription = volumeInfo["description"].string
        
        // Add a link at which a front cover image can be found.
        // The link seems to be equally accessible at https, and iOS apps don't seem to like
        // accessing http addresses, so adjust the provided url.
        result.imageURL = volumeInfo["imageLinks"]["thumbnail"].string?.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        return result
    }
}