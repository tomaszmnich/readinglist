//
//  OpenLibraryParser.swift
//  books
//
//  Created by Andrew Bennet on 30/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import SwiftyJSON

enum OpenLibraryRequest {
    
    case GetIsbn(String)
    
    // The base URL for OpenLibrary's API
    static let baseURLString = "https://openlibrary.org/api"
    
    var url: String {
        switch self{
        case let GetIsbn(isbn):
            return "\(OpenLibraryRequest.baseURLString)books?bibkeys=ISBN:\(isbn)&jscmd=data&format=json"
        }
    }
}

class OpenLibraryParser: BookParser {
    
    static func ParseJsonResponse(jResponse: JSON) -> BookMetadata? {
        
        // Books with no title are useless
        guard let title = jResponse["title"].string else {
            return nil
        }
        
        // Build the metadata
        let book = BookMetadata()
        book.title = title
        book.pageCount = jResponse["number_of_pages"].int
        book.authorList = jResponse["authors"].map{$1["name"].string!}.joinWithSeparator(", ")
        book.publishedDate = jResponse["publish_date"].string?.toDateViaFormat("yyyy-MM-dd")
        
        // Add a link at which a front cover image can be found.
        if let coverUrlString = jResponse["cover"]["medium"].string {
            book.coverUrl = NSURL(string: coverUrlString)
        }
        
        return book
    }
}