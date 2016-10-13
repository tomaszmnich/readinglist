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
    static func parse(response: JSON, maxResultCount: Int) -> [BookMetadata]
}

class OnlineBookClient<TParser: BookParser>{
    
    static func getBookMetadata(from url: URL, maxResults: Int, onError: @escaping ((Error) -> Void), onSuccess: @escaping (([BookMetadata]) -> Void)) {
        
        func successCallback(_ result: JSON?) {
            guard let result = result else { onSuccess([BookMetadata]()); return }
            
            let results = TParser.parse(response: result, maxResultCount: maxResults)
            
            let resultsWithCoverUrl = results.filter{ $0.coverUrl != nil }
            var extraCallsReturned = 0
            
            for result in resultsWithCoverUrl {
                // Request the book cover image too, and call the completion handler
                HttpClient.getData(result.coverUrl!, onError: onError) {
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
        HttpClient.getJson(url, onError: onError, onSuccess: successCallback)
    }
}
