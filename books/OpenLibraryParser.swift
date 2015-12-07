//
//  OpenLibraryParser.swift
//  books
//
//  Created by Andrew Bennet on 02/12/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import SwiftyJSON

/// Deals with parsing the JSON returned by OpenLibrary's API into object representations.
class OpenLibraryParser {
    
    /// Parses a JSON OpenLibrary response and returns the corresponding ParsedBookResult.
    static func parseJsonResponse(jResponse: JSON) -> BookMetadata {
        // Prepare the result
        let result = BookMetadata(bookSource: BookSource.OpenLibrary)
        
        // Add the title
        result.title = jResponse[0]["title"].string
        print(jResponse[0].string)
        
        
        // Add all the authors
        let authors = jResponse[0]["authors"]
        for author in authors{
            if let authorName = author.1["name"].string {
                result.authors.append(authorName)
            }
        }
        
        // Add a link at which a front cover image can be found
        result.imageURL = jResponse["cover"]["medium"].string
        
        return result
    }
}