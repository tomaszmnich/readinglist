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
    static func GetJson(fromUrl: String, callback: (JSON?, NSError?) -> Void) {
        
        print("Requesting \(fromUrl)")
        
        Alamofire.request(.GET, fromUrl).responseJSON {
            var jsonResponse: JSON?
            
            if $0.result.isSuccess {
                if let responseData = $0.result.value {
                    jsonResponse = JSON(responseData)
                }
            }
            else{
                callback(nil, $0.result.error)
            }
            
            // Callback on the main thread
            dispatch_async(dispatch_get_main_queue()) {
                callback(jsonResponse, nil)
            }
        }
    }
    
    /**
     Requests the data from the url, and passes the NSData into the callback.
     */
    static func GetData(fromUrl: String, callback: (NSData?, NSError?) -> Void){
        print("Requesting \(fromUrl)")
        
        // Make a request for the data
        Alamofire.request(.GET, fromUrl).response {
            (_, _, data, error) in
            
            let nsData = data as NSData?
            dispatch_async(dispatch_get_main_queue()) {
                if error != nil {
                    callback(nil, error)
                }
                else {
                    callback(nsData, nil)
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