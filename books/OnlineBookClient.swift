//
//  OnlineBooksClient.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON

class OnlineBookClient<TParser: BookParser>{
    
    static func TryGetBookMetadata(searchUrl: String, completionHandler: (BookMetadata? -> Void)) {
        var bookMetadata: BookMetadata?
        
        func SearchResultCallback(result: JSON?) {
            if let result = result {
                
                // Parse the online response
                if let bookMetadata = TParser.ParseJsonResponse(result) {
                    
                    // If there was an image URL in the result, request that too
                    if let dataUrl = bookMetadata.coverUrl {
                        HttpClient.GetData(dataUrl) {
                            bookMetadata.coverImage = $0
                            completionHandler(bookMetadata)
                        }
                        return
                    }
                }
            }
            completionHandler(bookMetadata)
        }
        
        HttpClient.GetJson(searchUrl, callback: SearchResultCallback)
    }
}
