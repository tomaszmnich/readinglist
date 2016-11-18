//
//  GoogleBooksAPI.swift
//  books
//
//  Created by Andrew Bennet on 12/11/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

class GoogleBooksAPI {
    
    static func getData(_ url: URL) -> Observable<Data> {
        return Observable<Data>.create { observable -> Disposable in
            print("Requesting \(url)")
            let requestReference = Alamofire.request(url).responseData {
                if $0.result.isSuccess, let data = $0.result.value {
                    observable.onNext(data)
                }
                else {
                    observable.onError($0.result.error!)
                }
                observable.onCompleted()
            }
            return Disposables.create {
                requestReference.cancel()
            }
            
        }
    }
    
    static func search(_ searchString: String) -> Observable<[BookMetadata]> {
        return Observable<[BookMetadata]>.create { (observer) -> Disposable in
            if searchString.isEmptyOrWhitespace {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }
            print("requesting search for \(searchString)")
            let requestReference = Alamofire.request(GoogleBooksRequest.search(searchString).url).responseJSON {
                if $0.result.isSuccess, let response = $0.result.value {
                    observer.onNext(GoogleBooksParser.parse(response: JSON(response)))
                }
                else {
                    observer.onError($0.result.error!)
                }
                observer.onCompleted()
            }
            return Disposables.create {
                requestReference.cancel()
            }
        }
    }
    
    static func search(_ searchString: String, callback: @escaping ([BookMetadata]?, Error?) -> Void) {
        Alamofire.request(GoogleBooksRequest.search(searchString).url).responseJSON {
            if $0.result.isSuccess, let response = $0.result.value {
                callback(GoogleBooksParser.parse(response: JSON(response)), nil)
            }
            else {
                callback(nil, $0.result.error)
            }
        }
    }
    
    static func lookupIsbn(_ isbn: String, callback: @escaping (BookMetadata?, Error?) -> Void) {
        Alamofire.request(GoogleBooksRequest.getIsbn(isbn).url).responseJSON {
            if $0.result.isSuccess, let response = $0.result.value {
                callback(GoogleBooksParser.parseFirst(response: JSON(response)), nil)
            }
            else {
                callback(nil, $0.result.error)
            }
        }
    }
    
    fileprivate enum GoogleBooksRequest {
        
        case search(String)
        case getIsbn(String)
        
        // The base URL for GoogleBooks API v1 requests
        private static let baseUrl = URL(string: "https://www.googleapis.com")!
        
        var url: URL {
            switch self{
            case let .search(query):
                let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                return URL(string: "/books/v1/volumes?q=\(encodedQuery)", relativeTo: GoogleBooksRequest.baseUrl)!
            case let .getIsbn(isbn):
                return URL(string: "/books/v1/volumes?q=isbn:\(isbn)", relativeTo: GoogleBooksRequest.baseUrl)!
            }
        }
    }
    
    fileprivate class GoogleBooksParser {
        
        static func parseFirst(response: JSON) -> BookMetadata? {
            guard let firstItem = response["items"].first else { return nil }
            return parse(item: firstItem.1)
        }
        
        static func parse(response: JSON) -> [BookMetadata] {
            return response["items"].flatMap {
                return parse(item: $0.1)
            }
        }
        
        private static func parse(item: JSON) -> BookMetadata? {
            let volumeInfo = item["volumeInfo"]
            
            // Books with no title are useless
            guard let title = volumeInfo["title"].string else { return nil }
            
            // Build the metadata
            let book = BookMetadata()
            book.title = title
            book.pageCount = volumeInfo["pageCount"].int
            book.bookDescription = volumeInfo["description"].string
            book.authorList = volumeInfo["authors"].map{$1.rawString()!}.joined(separator: ", ")
            book.publishedDate = volumeInfo["publishedDate"].string?.toDateViaFormat("yyyy-MM-dd")
            
            // Add a link at which a front cover image can be found.
            // The link seems to be equally accessible at https, and iOS apps don't seem to like
            // accessing http addresses, so adjust the provided url.
            if let url = volumeInfo["imageLinks"]["thumbnail"].string?.replacingOccurrences(of: "http://", with: "https://"){
                book.coverUrl = URL(string: url)
            }
            return book
        }
    }
}
