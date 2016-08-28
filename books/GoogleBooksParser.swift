//
//  GoogleBooksParser.swift
//  books
//
//  Created by Andrew Bennet on 25/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import SwiftyJSON

/// Builds a request to perform an operation on the GoogleBooks API.
enum GoogleBooksRequest {
    
    case Search(String)
    case GetIsbn(String)
    
    // The base URL for GoogleBooks API v1 requests
    static let baseUrl = NSURL(string: "https://www.googleapis.com")!
    
    var url: NSURL {
        switch self{
        case let Search(query):
            let encodedQuery = query.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            return NSURL(string: "/books/v1/volumes?q=\(encodedQuery)", relativeToURL: GoogleBooksRequest.baseUrl)!
        case let GetIsbn(isbn):
            return NSURL(string: "/books/v1/volumes?q=isbn:\(isbn)", relativeToURL: GoogleBooksRequest.baseUrl)!
        }
    }
}

/// Deals with parsing the JSON returned by GoogleBook's API into object representations.
class GoogleBooksParser: BookParser {
    
    static func ParseJsonResponse(jResponse: JSON, maxResultCount: Int) -> [BookMetadata] {
        var results = [BookMetadata]()
        
        // The information we seek is in the volumneInfo element.
        let items = jResponse["items"]
        for item in items {
            if let result = ParseItem(item.1) {
                results.append(result)
            }
            if results.count >= maxResultCount {
                break
            }
        }
        
        return results
    }
    
    private static func ParseItem(item: JSON) -> BookMetadata? {
        let volumeInfo = item["volumeInfo"]
        
        // Books with no title are useless
        guard let title = volumeInfo["title"].string else { return nil }
        
        // Build the metadata
        let book = BookMetadata()
        book.title = title
        book.subtitle = volumeInfo["subtitle"].string
        book.pageCount = volumeInfo["pageCount"].int
        book.bookDescription = volumeInfo["description"].string
        book.authorList = volumeInfo["authors"].map{$1.rawString()!}.joinWithSeparator(", ")
        book.publishedDate = volumeInfo["publishedDate"].string?.toDateViaFormat("yyyy-MM-dd")
        
        // Add a link at which a front cover image can be found.
        // The link seems to be equally accessible at https, and iOS apps don't seem to like
        // accessing http addresses, so adjust the provided url.
        if let url = volumeInfo["imageLinks"]["thumbnail"].string?.stringByReplacingOccurrencesOfString("http://", withString: "https://"){
            book.coverUrl = NSURL(string: url)
        }
        return book
    }
}