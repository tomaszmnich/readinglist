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
    static func GetJson(_ from: URL, onError: @escaping ((Error) -> Void), onSuccess: @escaping ((JSON?) -> Void)) {
        print("Requesting \(from.absoluteString)")
        
        Alamofire.request(from).responseJSON {
            if $0.result.isSuccess {
                if let responseData = $0.result.value {
                    // Callback on the main thread
                    DispatchQueue.main.async {
                        onSuccess(JSON(responseData))
                    }
                }
            }
            else if let error = $0.result.error {
                // Callback on the main thread
                DispatchQueue.main.async {
                    onError(error)
                }
            }
        }
    }
    
    /**
     Requests the data from the url, and passes the NSData into the callback.
     */
    static func GetData(_ from: URL, onError: @escaping ((Error) -> Void), onSuccess: @escaping ((Data?) -> Void)) {
        print("Requesting \(from.absoluteString)")
        
        // Make a request for the data
        Alamofire.request(from).responseData {
            if let error = $0.result.error {
                DispatchQueue.main.async{
                    onError(error)
                }
            }
            else {
                let nsData = $0.data as Data?
                DispatchQueue.main.async {
                    onSuccess(nsData)
                }
            }
        }
    }
}
