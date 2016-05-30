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
    static let baseURLString = "https://www.googleapis.com/books/v1"
    
    var url: String {
        switch self{
        case let Search(query):
            return "\(GoogleBooksRequest.baseURLString)/volumes?q=\(query)"
        case let GetIsbn(isbn):
            return "\(GoogleBooksRequest.baseURLString)/volumes?q=isbn:\(isbn)"
        }
    }
}

/// Deals with parsing the JSON returned by GoogleBook's API into object representations.
class GoogleBooksParser: BookParser {
    
    static func ParseJsonResponse(jResponse: JSON) -> BookMetadata? {
        
        // The information we seek is in the volumneInfo element.
        let volumeInfo = jResponse["items"][0]["volumeInfo"]
        
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
        book.coverUrl = volumeInfo["imageLinks"]["thumbnail"].string?.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        return book
    }
}