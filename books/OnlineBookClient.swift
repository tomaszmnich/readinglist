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
    
    static func TryGetBookMetadata(from url: NSURL, onError: (NSError -> Void), onSuccess: (BookMetadata? -> Void)) {
        
        func SuccessCallback(result: JSON?) {
            // First check there is a JSON result, and it can be parsed.
            guard let result = result,
                let bookMetadata = TParser.ParseJsonResponse(result) else { onSuccess(nil); return }
            
            // Then check whether there was a book cover image URL.
            if let bookCoverUrl = bookMetadata.coverUrl {
                // Request the book cover image too, and call the completion handler
                HttpClient.GetData(bookCoverUrl, onError: onError) {
                    bookMetadata.coverImage = $0
                    onSuccess(bookMetadata)
                }
            }
            else {
                onSuccess(bookMetadata)
            }
        }
        
        // Make the request!
        HttpClient.GetJson(url, onError: onError, onSuccess: SuccessCallback)
    }
}
