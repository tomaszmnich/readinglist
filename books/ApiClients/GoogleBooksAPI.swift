//
//  GoogleBooksAPI.swift
//  books
//
//  Created by Andrew Bennet on 12/11/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift

enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var successValue: Value? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }
    
    var failureError: Error? {
        switch self {
        case let .failure(error):
            return error
        case .success:
            return nil
        }
    }
}

class GoogleBooksAPI {
    
    static func search(_ searchString: String) -> Observable<Result<[BookMetadata]>> {
        return requestAndParseAndObserve(url: GoogleBooksRequest.search(searchString).url)
    }
    
    /// Gets up to 1 result, by ISBN. Supplements the book result with the image data
    static func get(isbn: String, callback: @escaping (BookMetadata?, Error?) -> Void) {
        requestAndParse(url: GoogleBooksRequest.getIsbn(isbn).url) { results, error in
            
            guard let result = results?.first else {
                callback(nil, error)
                return
            }

            // Attach the original ISBN if there wasn't one in the result
            if result.isbn13 == nil {
                result.isbn13 = isbn
            }
            
            // If there is image URL information, grab the image and add that before running the callback
            supplementMetadataWithImage(result) {
                callback(result, error)
            }
        }
    }
    
    static func supplementMetadataWithImage(_ metadata: BookMetadata, completion: @escaping () -> ()){
        // Quick return if no image URL available
        guard let coverUrl = metadata.coverUrl else {
            completion()
            return
        }
        
        let searchRequest = URLSession.shared.dataTask(with: coverUrl) { (data, _, error) in
            metadata.coverImage = data
            completion()
        }
        searchRequest.resume()
    }
    
    private static func requestAndParseAndObserve(url: URL) -> Observable<Result<[BookMetadata]>> {
        return Observable<Result<[BookMetadata]>>.create { observer -> Disposable in
            
            let searchRequest = GoogleBooksAPI.requestAndParse(url: url) { bookMetadatas, error in
                if let bookMetadatas = bookMetadatas {
                    observer.onNext(Result.success(bookMetadatas))
                    observer.onCompleted()
                }
                else if let error = error {
                    observer.onNext(Result.failure(error))
                    observer.onCompleted()
                }
            }
            
            return Disposables.create {
                searchRequest.cancel()
            }
        }
    }
    
    @discardableResult private static func requestAndParse(url: URL, callback: @escaping ([BookMetadata]?, Error?) -> Void) -> URLSessionDataTask {
        let searchRequest = URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let json = JSON(optionalData: data) {
                callback(GoogleBooksParser.parse(response: json), nil)
            }
            else {
                callback(nil, error)
            }
        }
        searchRequest.resume()
        return searchRequest
    }
    
    private enum GoogleBooksRequest {
        
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
    
    private class GoogleBooksParser {
        
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
            book.isbn13 = volumeInfo["industryIdentifiers"].array?.first(where: { json in
                return json["type"].stringValue == "ISBN_13"
            })?["identifier"].stringValue
            
            // Add a link at which a front cover image can be found.
            // The link seems to be equally accessible at https, and iOS apps don't seem to like
            // accessing http addresses, so adjust the provided url.
            // FUTURE: Do this better
            if let url = volumeInfo["imageLinks"]["thumbnail"].string?.replacingOccurrences(of: "http://", with: "https://"){
                book.coverUrl = URL(string: url)
            }
            return book
        }
    }
}
