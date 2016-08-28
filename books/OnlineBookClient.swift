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
    static func ParseJsonResponse(jResponse: JSON, maxResultCount: Int) -> [BookMetadata]
}

class OnlineBookClient<TParser: BookParser>{
    
    static func TryGetBookMetadata(from url: NSURL, maxResults: Int, onError: (NSError -> Void), onSuccess: ([BookMetadata] -> Void)) {
        
        func SuccessCallback(result: JSON?) {
            guard let result = result else { onSuccess([BookMetadata]()); return }
            
            let results = TParser.ParseJsonResponse(result, maxResultCount: maxResults)
            
            let resultsWithCoverUrl = results.filter{ $0.coverUrl != nil }
            var extraCallsReturned = 0
            
            for result in resultsWithCoverUrl {
                // Request the book cover image too, and call the completion handler
                HttpClient.GetData(result.coverUrl!, onError: onError) {
                    result.coverImage = $0
                    extraCallsReturned += 1
                    if extraCallsReturned == resultsWithCoverUrl.count {
                        onSuccess(results)
                    }
                }
            }
            
            if resultsWithCoverUrl.count == 0 {
                onSuccess(results)
            }
        }
        
        // Make the request!
        HttpClient.GetJson(url, onError: onError, onSuccess: SuccessCallback)
    }
}
