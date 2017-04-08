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
    
    /**
     Searches on Google Books for the given search string, and calls the callback when a result is received
    */
    static func searchText(_ text: String, callback: @escaping (Result<[GoogleBooksSearchResult]>) -> Void) -> URLSessionDataTask {
        let request = GoogleBooksRequest.searchText(text)
        return requestJson(from: request.url) { json, error in
            guard let json = json, error == nil else { callback(Result.failure(error!)); return }
            callback(Result.success(GoogleBooksParser.parseSearchResults(json)))
        }
    }
    
    /**
     Observable version of searchText function.
    */
    static func searchText(_ text: String) -> Observable<Result<[GoogleBooksSearchResult]>> {
        return Observable<Result<[GoogleBooksSearchResult]>>.create { observer -> Disposable in
            let searchRequest = searchText(text) { result in
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create {
                searchRequest.cancel()
            }
        }
    }
    
    /**
     Searches on Google Books for the given search string, and calls the callback when a result is received.
     Runs the callback on the Main DispatchQueue.
     */
    static func fetchIsbn(_ isbn: String, callback: @escaping (Result<BookMetadata?>) -> Void) {
        let request = GoogleBooksRequest.searchIsbn(isbn)
        requestJson(from: request.url) { json, error in
            guard let json = json, error == nil else { callback(Result.failure(error!)); return }
            guard let searchResult = GoogleBooksParser.parseSearchResults(json).first else { callback(Result.success(nil)); return }
            
            GoogleBooksAPI.fetch(googleBooksId: searchResult.id, callback: callback)
        }
    }
    
    /**
     Fetches the specified book from Google Books. Runs the callback on the Main DispatchQueue
     */
    static func fetch(googleBooksId: String, callback: @escaping (Result<BookMetadata?>) -> Void) {
        let request = GoogleBooksRequest.fetch(googleBooksId)
        let dispatchGroup = DispatchGroup()
        
        requestJson(from: request.url, dispatchGroup: dispatchGroup) { json, error in
            guard let json = json, error == nil else { callback(Result.failure(error!)); return }
            let fetchResult = GoogleBooksParser.parseFetchResults(json)
            guard let fetchedMetadata = fetchResult.0 else { callback(Result.success(nil)); return }
            
            if let coverUrl = fetchResult.1 {
                GoogleBooksAPI.requestData(from: coverUrl, dispatchGroup: dispatchGroup) { data, error in
                    fetchedMetadata.coverImage = data
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                callback(Result.success(fetchedMetadata))
            }
        }
    }
    
    @discardableResult private static func requestJson(from url: URL, dispatchGroup: DispatchGroup? = nil, callback: @escaping (JSON?, Error?) -> Void) -> URLSessionDataTask {
        let webRequest = URLSession.shared.dataTask(with: url) { (data, _, error) in
            let json = JSON(optionalData: data)
            callback(json, error)
            dispatchGroup?.leave()
        }
        dispatchGroup?.enter()
        webRequest.resume()
        return webRequest
    }
    
    @discardableResult private static func requestData(from url: URL, dispatchGroup: DispatchGroup? = nil, callback: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask {
        let webRequest = URLSession.shared.dataTask(with: url) { (data, _, error) in
            callback(data, error)
            dispatchGroup?.leave()
        }
        dispatchGroup?.enter()
        webRequest.resume()
        return webRequest
    }
    
    enum GoogleBooksRequest {
        
        case searchText(String)
        case searchIsbn(String)
        case fetch(String)
        
        // The base URL for GoogleBooks API v1 requests
        private static let baseUrl = URL(string: "https://www.googleapis.com")!
        
        private static let searchResultFields = "items(id,volumeInfo(title,authors,industryIdentifiers,imageLinks/thumbnail))"
        
        var url: URL {
            switch self{
            case let .searchText(searchString):
                let encodedQuery = searchString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                return URL(string: "/books/v1/volumes?q=\(encodedQuery)&maxResults=40&fields=\(GoogleBooksRequest.searchResultFields)", relativeTo: GoogleBooksRequest.baseUrl)!
                
            case let .searchIsbn(isbn):
                return URL(string: "/books/v1/volumes?q=isbn:\(isbn)&maxResults=1&fields=\(GoogleBooksRequest.searchResultFields)", relativeTo: GoogleBooksRequest.baseUrl)!
                
            case let .fetch(id):
                return URL(string: "/books/v1/volumes/\(id)", relativeTo: GoogleBooksRequest.baseUrl)!
            }
        }
    }
    
    // TODO: Unit test
    class GoogleBooksParser {
        
        static func parseSearchResults(_ searchResults: JSON) -> [GoogleBooksSearchResult] {
            return searchResults["items"].flatMap { itemJson in
                guard let item = GoogleBooksParser.parseItem(itemJson.1) else { return nil }
                return item
            }
        }
        
        static func parseItem(_ item: JSON) -> GoogleBooksSearchResult? {
            guard let id = item["id"].string,
                let title = item["volumeInfo", "title"].string,
                let authors = item["volumeInfo", "authors"].array else { return nil }
                
            let singleAuthorListString = authors.map{$0.rawString()!}.joined(separator: ", ")
            var result = GoogleBooksSearchResult(id: id, title: title, authors: singleAuthorListString)
            
            result.thumbnailCoverUrl = URL(optionalString: item["volumeInfo","imageLinks","thumbnail"].string)?.toHttps()
            /*result.isbn13 = item["volumeInfo","industryIdentifiers"].array?.first(where: { json in
                return json["type"].stringValue == "ISBN_13"
            })?["identifier"].stringValue*/
            
            return result
        }
        
        static func parseFetchResults(_ fetchResult: JSON) -> (BookMetadata?, URL?) {
            
            // Defer to the common search parsing initially
            guard let searchResult = GoogleBooksParser.parseItem(fetchResult) else { return (nil, nil) }
            
            let result = BookMetadata(googleBooksId: searchResult.id, title: searchResult.title, authors: searchResult.authors)
            result.isbn13 = searchResult.isbn13
            result.pageCount = fetchResult["volumeInfo","pageCount"].int
            result.publishedDate = fetchResult["volumeInfo","publishedDate"].string?.toDateViaFormat("yyyy-MM-dd")
            
            // This string may contain some HTML. We want to remove them, but first we might as well replace the "<br>"s with '\n'
            var description = fetchResult["volumeInfo","description"].string
            description = description?.replacingOccurrences(of: "<br>", with: "\n")
            description = description?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            result.bookDescription = description
            
            // The "small" image is bigger than the thumbnail. Use it if available, otherwise revert back to the thumbnail
            let smallCoverUrl = URL(optionalString: fetchResult["volumeInfo","imageLinks","small"].string)?.toHttps() ?? searchResult.thumbnailCoverUrl

            return (result, smallCoverUrl)
        }
    }
}

struct GoogleBooksSearchResult {
    let id: String
    var title: String
    var authors: String
    var isbn13: String?
    var thumbnailCoverUrl: URL?
    
    init(id: String, title: String, authors: String) {
        self.id = id
        self.title = title
        self.authors = authors
    }
}
