//
//  GoogleBooksParser.swift
//  books
//
//  Created by Andrew Bennet on 25/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import SwiftyJSON

class GoogleBooksParser {
    static func parseJsonResponse(jResponse: JSON) -> ParsedBookResult {
        // Prepare the result
        let result = ParsedBookResult()
        
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
        result.imageURL = volumeInfo["imageLinks"]["thumbnail"].string?.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        return result
    }
}

class ParsedBookResult {
    var title: String?
    var authors = [String]()
    var imageURL: String?
    var imageData: NSData?
    var isbn13: String?
}