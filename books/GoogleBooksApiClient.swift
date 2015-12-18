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
     Executes a search on the Google Books API for a given ISBN, and returns
     the parsed result obtained, if there was one.
    */
    static func SearchByIsbn(isbn: String!, callback: (parsedResult: BookMetadata?) -> Void) {
        
        var parsedResult: BookMetadata?
        
        // Request the metadata first
        let searchRequestUrl = GoogleBooksRequest.Search(isbn).url

        print("Requesting \(searchRequestUrl)")
        Alamofire.request(.GET, searchRequestUrl).responseJSON {
            if($0.result.isSuccess){
                // Get a ParsedBookResult with some populated metadata
                parsedResult = HandleSuccessfulIsbnResponse(isbn, response: $0)
                
                // If the metadata contained an image URL, request that too
                SupplementWithImageAndCallback(parsedResult, callback: callback)
            }
            else{
                LogError($0)
            }
        }
    }
    
    /**
     Responds to a successful response after a search for an ISBN.
     Constructs a ParsedBookResult to represent the metadata obtained.
    */
    private static func HandleSuccessfulIsbnResponse(isbn: String, response: Response<AnyObject, NSError>) -> BookMetadata? {
        print("Success response received")
        var parsedResult: BookMetadata!
        if let responseData = response.result.value {
            parsedResult = GoogleBooksParser.parseJsonResponse(isbn, jResponse: JSON(responseData))
            print("Parsed response.")
        }
        return parsedResult
    }
    
    /**
     Takes a ParsedBookResult and, if there is a URL for a cover image,
     attempts to download the image an attach the data to the ParsedBookResult.
    */
    private static func SupplementWithImageAndCallback(parsedBook: BookMetadata!, callback: (parsedResult: BookMetadata!) -> Void){

        // Only proceed if there is a parsedBook with a image URL
        if let imageUrl = parsedBook?.imageURL{
            print("Requesting \(imageUrl)")
            
            // Make a request for the data
            Alamofire.request(.GET, imageUrl).response {
                (_, _, data, _) in
                print("Response received")

                if let image = data! as NSData? {
                    parsedBook.imageData = image
                }
                else{
                    print("No image data")
                }
                dispatch_async(dispatch_get_main_queue()) {
                    callback(parsedResult: parsedBook)
                }
            }
        }
        else{
            dispatch_async(dispatch_get_main_queue()) {
                callback(parsedResult: parsedBook)
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