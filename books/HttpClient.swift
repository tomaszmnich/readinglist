//
//  HttpClient.swift
//  books
//
//  Created by Andrew Bennet on 26/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class HttpClient{
    
    /**
     Gets the content of a given URL, casted to JSON, and executes the provided callback on the main thread.
     */
    static func GetJson(from: NSURL, onError: (NSError -> Void), onSuccess: (JSON? -> Void)) {
        print("Requesting \(from.absoluteString)")
        
        Alamofire.request(.GET, from).responseJSON {
            if $0.result.isSuccess {
                if let responseData = $0.result.value {
                    // Callback on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        onSuccess(JSON(responseData))
                    }
                }
            }
            else if let error = $0.result.error {
                // Callback on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    onError(error)
                }
            }
        }
    }
    
    /**
     Requests the data from the url, and passes the NSData into the callback.
     */
    static func GetData(from: NSURL, onError: (NSError -> Void), onSuccess: (NSData? -> Void)) {
        print("Requesting \(from.absoluteString)")
        
        // Make a request for the data
        Alamofire.request(.GET, from).response {
            (_, _, data, error) in
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue()){
                    onError(error)
                }
            }
            else {
                let nsData = data as NSData?
                dispatch_async(dispatch_get_main_queue()) {
                    onSuccess(nsData)
                }
            }
        }
    }
    
    /// Logs an error from a response
    private static func LogError(response: Response<AnyObject, NSError>){
        print("Error response received")
        print(response.result.error)
    }
    
}