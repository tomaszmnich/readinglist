//
//  OnlineBooksClient.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

protocol BookParser {
    static func parse(response: JSON, maxResultCount: Int) -> [BookMetadata]
}

class OnlineBookClient<TParser: BookParser> {
    
    static func getBookMetadata(from url: URL, maxResults: Int, onError: @escaping ((Error) -> Void), onSuccess: @escaping (([BookMetadata]) -> Void)) {
        
        // Make the request!
        Alamofire.request(url).responseJSON {
            if $0.result.isSuccess, let responseData = $0.result.value {
                let results = TParser.parse(response: JSON(responseData), maxResultCount: maxResults)
                
                let resultsWithCoverUrl = results.filter{ $0.coverUrl != nil }
                var extraCallsReturned = 0
                
                for result in resultsWithCoverUrl {
                    // Request the book cover image too
                    Alamofire.request(result.coverUrl!).responseData {
                        if let error = $0.result.error {
                            onError(error)
                        }
                        else {
                            result.coverImage = $0.data
                            extraCallsReturned += 1
                            if extraCallsReturned == resultsWithCoverUrl.count {
                                onSuccess(results)
                            }
                        }
                    }
                }
            }
            else if let error = $0.result.error {
                onError(error)
            }
        }
    }
}
