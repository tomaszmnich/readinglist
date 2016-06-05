//
//  OnlineBooksClient.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol BookParser {
    static func ParseJsonResponse(jResponse: JSON) -> BookMetadata?
}

class OnlineBookClient<TParser: BookParser>{
    
    static func TryGetBookMetadata(searchUrl: String, completionHandler: (BookMetadata? -> Void)) {
        
        func SearchResultCallback(result: JSON?) {
            
            // First check there is a JSON result, and it can be parsed.
            guard let result = result,
                let bookMetadata = TParser.ParseJsonResponse(result)
                else { completionHandler(nil); return }
            
            // Then check whether there was a book cover image URL.
            guard let bookCoverUrl = bookMetadata.coverUrl else { completionHandler(bookMetadata); return }
            
            // Request the book cover image too, and call the completion handler
            HttpClient.GetData(bookCoverUrl) {
                bookMetadata.coverImage = $0
                completionHandler(bookMetadata)
            }
        }
        
        // Make the request!
        HttpClient.GetJson(searchUrl, callback: SearchResultCallback)
    }
}
