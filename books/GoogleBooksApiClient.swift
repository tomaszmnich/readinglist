//
//  GoogleBooksApiClient.swift
//  books
//
//  Created by Andrew Bennet on 27/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Alamofire
import SwiftyJSON

// Interacts with the GoogleBooks API
class GoogleBooksApiClient {
    
    // Executes a search on the Google Books API for a given ISBN, and returns
    // the parsed result obtained, if there was one.
    static func SearchByIsbn(isbn: String!, callback: (parsedResult: ParsedBookResult?) -> Void) {
        
        var parsedResult: ParsedBookResult?
        
        // Request the metadata first
        let searchRequestUrl = GoogleBooksRequest.Search(isbn).url

        print("Requesting \(searchRequestUrl)")
        Alamofire.request(.GET, searchRequestUrl).responseJSON {
            response in
            
            if(response.result.isSuccess){
                // Get a ParsedBookResult with some populated metadata
                parsedResult = HandleSuccessfulIsbnResponse(response)
                
                // If the metadata contained an image URL, request that too
                SupplementWithImage(parsedResult)
            }
            else{
                LogError(response)
            }
            
            // Call into the supplied callback
            callback(parsedResult: parsedResult)
        }
    }
    
    // Responds to a successful response after a search for an ISBN.
    // Constructs a ParsedBookResult to represent the metadata obtained.
    private static func HandleSuccessfulIsbnResponse(response: Response<AnyObject, NSError>) -> ParsedBookResult? {
        var parsedResult: ParsedBookResult?
        
        print("Success response received")
        if let responseData = response.result.value {
            parsedResult = GoogleBooksParser.parseJsonResponse(JSON(responseData))
        }
        print("Parsed result: \(parsedResult)")
        return parsedResult
    }
    
    // Takes a ParsedBookResult and, if there is a URL for a cover image, 
    // attempts to download the image an attach the data to the ParsedBookResult.
    private static func SupplementWithImage(parsedBook: ParsedBookResult?){

        // Only proceed if there is a parsedBook with a image URL
        if let imageUrl = parsedBook?.imageURL{
            print("Requesting \(imageUrl)")
            
            // Make a request for the data
            Alamofire.request(.GET, imageUrl).responseJSON {
                response in
                if(response.result.isSuccess){
                    
                    // If we are successful, load the data wholesale into the imageData property
                    print("Success response received")
                    parsedBook!.imageData = response.data
                }
                else{
                    LogError(response)
                }
            }
        }
    }
    
    // Logs an error from a response
    private static func LogError(response: Response<AnyObject, NSError>){
        print("Error response received")
        print(response.result.error)
    }
}

// Builds a request to perform an operation on the GoogleBooks API.
enum GoogleBooksRequest {

    case Search(String)
    
    // The base URL for GoogleBooks API v1 requests
    static let baseURLString = "https://www.googleapis.com/books/v1"
    
    var url: String {
    switch self{
        case let Search(query):
            return GoogleBooksRequest.baseURLString + "/volumes?q=" + query
        }
    }
}