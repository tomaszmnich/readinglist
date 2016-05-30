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
            guard let result = result, let bookMetadata = TParser.ParseJsonResponse(result) else {
                completionHandler(nil)
                return
            }
            
            // Then, if there was an image URL in the result, request that too
            if let dataUrl = bookMetadata.coverUrl {
                HttpClient.GetData(dataUrl) {
                    bookMetadata.coverImage = $0
                    completionHandler(bookMetadata)
                }
            }
            else {
                completionHandler(bookMetadata)
            }
        }
        
        // Make the request!
        HttpClient.GetJson(searchUrl, callback: SearchResultCallback)
    }
}
