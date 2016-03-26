//
//  GoogleBooksApiClient.swift
//  books
//
//  Created by Andrew Bennet on 27/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Alamofire
import AlamofireImage
import SwiftyJSON

/// Interacts with the GoogleBooks API
class GoogleBooksApiClient {
    
    /**
     Executes a search on the Google Books API for a given ISBN, and passes the JSON into the callback.
    */
    static func SearchByIsbn(isbn: String!, callback: (jsonResponse: JSON?) -> Void) {
        
        // Request the metadata
        let searchRequestUrl = GoogleBooksRequest.Search(isbn).url
        print("Requesting \(searchRequestUrl)")
        Alamofire.request(.GET, searchRequestUrl).responseJSON {
            var jsonResponse: JSON?
            
            if $0.result.isSuccess {
                if let responseData = $0.result.value {
                    jsonResponse = JSON(responseData)
                }
            }
            else{
                LogError($0)
            }
            
            // Callback on the main thread
            dispatch_async(dispatch_get_main_queue()) {
                print("Executing SearchByIsbn callback")
                callback(jsonResponse: jsonResponse)
            }
        }
    }
    
    /**
     Requests the data from the url, and passes the NSData into the callback.
    */
    static func GetDataFromUrl(url: String, callback: (dataResponse: NSData?) -> Void){
        print("Requesting \(url)")
        
        // Make a request for the data
        Alamofire.request(.GET, url).response {
            (_, _, data, _) in
            print("Response received")
            
            let nsData = data! as NSData?
            dispatch_async(dispatch_get_main_queue()) {
                callback(dataResponse: nsData)
            }
        }
    }
    
    /// Logs an error from a response
    private static func LogError(response: Response<AnyObject, NSError>){
        print("Error response received")
        print(response.result.error)
    }
}

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