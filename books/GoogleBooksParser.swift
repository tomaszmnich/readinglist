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

protocol BookParser{
    static func parseJsonResponseIntoBook(bookToPopulate: Book, jResponse: JSON) -> Bool
}

/// Deals with parsing the JSON returned by GoogleBook's API into object representations.
class GoogleBooksParser: BookParser {
    
    /// Parses a JSON GoogleBooks response and returns the corresponding ParsedBookResult.
    static func parseJsonResponseIntoBook(bookToPopulate: Book, jResponse: JSON) -> Bool {
        print("Parsing JSON into book with id \(bookToPopulate.objectID.URIRepresentation())")
        
        // The information we seek is in the volumneInfo element.
        let volumeInfo = jResponse["items"][0]["volumeInfo"]

        if let title = volumeInfo["title"].string{
            bookToPopulate.title = title
        }
        else{
            return false
        }
        bookToPopulate.publishedDate = volumeInfo["publishedDate"].string
        bookToPopulate.publisher = volumeInfo["publisher"].string
        bookToPopulate.pageCount = volumeInfo["pageCount"].int
        bookToPopulate.bookDescription = volumeInfo["description"].string
        bookToPopulate.authorList = volumeInfo["authors"].map{$1.rawString()!}.joinWithSeparator(", ")
        
        // Add a link at which a front cover image can be found.
        // The link seems to be equally accessible at https, and iOS apps don't seem to like
        // accessing http addresses, so adjust the provided url.
        bookToPopulate.coverUrl = volumeInfo["imageLinks"]["thumbnail"].string?.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        return true
    }
}