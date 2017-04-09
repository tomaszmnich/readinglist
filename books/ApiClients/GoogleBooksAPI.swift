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

extension Observable {
    static func createFrom<E>(dataTaskCreator: @escaping (@escaping (E) -> Void) -> URLSessionDataTask) -> Observable<E> {
        return Observable<E>.create { observer -> Disposable in
            let dataTask = dataTaskCreator { result in
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create {
                dataTask.cancel()
            }
        }
    }
}

class GoogleBooksAPI {
    
    static func searchTextObservable(_ text: String) -> Observable<Result<GoogleBooksSearchResultPage>> {
        return Observable<Result<GoogleBooksSearchResultPage>>.createFrom { callback -> URLSessionDataTask in
            return GoogleBooksAPI.searchText(text, callback: callback)
        }
    }
    
    /**
     Searches on Google Books for the given search string, and calls the callback when a result is received
    */
    static func searchText(_ text: String, callback: @escaping (Result<GoogleBooksSearchResultPage>) -> Void) -> URLSessionDataTask {
        return requestJson(from: GoogleBooksRequest.searchText(text).url) { result in
            guard result.isSuccess else { callback(Result.failure(result.failureError!)); return }
            let results = GoogleBooksParser.parseSearchResults(result.successValue!)
            callback(Result.success(GoogleBooksSearchResultPage(searchText: text, results: results)))
        }
    }
    
    /**
     Searches on Google Books for the given search string, and calls the callback when a result is received.
     */
    static func fetchIsbn(_ isbn: String, callback: @escaping (Result<BookMetadata?>) -> Void) {
        requestJson(from: GoogleBooksRequest.searchIsbn(isbn).url) { result in
            guard result.isSuccess else { callback(Result.failure(result.failureError!)); return }
            guard let searchResult = GoogleBooksParser.parseSearchResults(result.successValue!).first else { callback(Result.success(nil)); return }
            
            GoogleBooksAPI.fetch(googleBooksId: searchResult.id, callback: callback)
        }
    }
    
    /**
     Fetches the specified book from Google Books.
     */
    static func fetch(googleBooksId: String, callback: @escaping (Result<BookMetadata?>) -> Void) {
        requestJson(from: GoogleBooksRequest.fetch(googleBooksId).url) { result in
            guard result.isSuccess else { callback(Result.failure(result.failureError!)); return }
            let parseResult = GoogleBooksParser.parseFetchResults(result.successValue!)
            guard let parsedMetadata = parseResult.0 else { callback(Result.success(nil)); return }
            
            // TODO: it would be better if we had a GoogleBooksFetchResult object which had a non-nil ID and held the cover URLs.
            // Also, constructing the URL manually is better, as we can remove the corner fold artifact
            if let coverUrl = parseResult.1 {
                GoogleBooksAPI.requestData(from: coverUrl) { result in
                    parsedMetadata.coverImage = result.successValue
                    callback(Result.success(parsedMetadata))
                }
            }
            else {
                callback(Result.success(parsedMetadata))
            }
        }
    }
    
    /**
     Gets the cover image data for the book corresponding to the Google Books ID (if exists).
    */
    static func getCover(googleBooksId: String, callback: @escaping (Result<Data>) -> Void) {
        requestData(from: GoogleBooksRequest.downloadCoverById(googleBooksId).url) { result in
            callback(result)
        }
    }
    
    enum RequestError: Error {
        case noJsonData
        case noData
    }
    
    @discardableResult private static func requestJson(from url: URL, callback: @escaping (Result<JSON>) -> Void) -> URLSessionDataTask {
        let webRequest = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard error == nil else { callback(Result.failure(error!)); return }
            guard let json = JSON(optionalData: data) else { callback(Result.failure(RequestError.noJsonData)); return }
            callback(Result<JSON>.success(json))
        }
        webRequest.resume()
        return webRequest
    }
    
    @discardableResult private static func requestData(from url: URL, callback: @escaping (Result<Data>) -> Void) -> URLSessionDataTask {
        let webRequest = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard error == nil else { callback(Result.failure(error!)); return }
            guard let data = data else { callback(Result.failure(RequestError.noData)); return }
            callback(Result<Data>.success(data))
        }
        webRequest.resume()
        return webRequest
    }
    
    enum GoogleBooksRequest {
        
        case searchText(String)
        case searchIsbn(String)
        case fetch(String)
        case downloadCoverById(String)
        
        // The base URL for GoogleBooks API v1 requests
        private static let apiBaseUrl = URL(string: "https://www.googleapis.com")!
        private static let googleBooksBaseUrl = URL(string: "https://books.google.com")!
        
        private static let searchResultFields = "items(id,volumeInfo(title,authors,industryIdentifiers,imageLinks/thumbnail))"
        
        var url: URL {
            switch self{
            case let .searchText(searchString):
                let encodedQuery = searchString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                return URL(string: "/books/v1/volumes?q=\(encodedQuery)&maxResults=40&fields=\(GoogleBooksRequest.searchResultFields)", relativeTo: GoogleBooksRequest.apiBaseUrl)!
                
            case let .searchIsbn(isbn):
                return URL(string: "/books/v1/volumes?q=isbn:\(isbn)&maxResults=1&fields=\(GoogleBooksRequest.searchResultFields)", relativeTo: GoogleBooksRequest.apiBaseUrl)!
                
            case let .fetch(id):
                return URL(string: "/books/v1/volumes/\(id)", relativeTo: GoogleBooksRequest.apiBaseUrl)!
            
            case let .downloadCoverById(googleBooksId):
                return URL(string: "/books/content?id=\(googleBooksId)&printsec=frontcover&img=1&zoom=2", relativeTo: GoogleBooksRequest.googleBooksBaseUrl)!
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
            result.isbn13 = item["volumeInfo","industryIdentifiers"].array?.first(where: { json in
                return json["type"].stringValue == "ISBN_13"
            })?["identifier"].stringValue
            
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

class GoogleBooksSearchResultPage {
    let searchResults: [GoogleBooksSearchResult]
    let searchText: String
    
    init(searchText: String, results: [GoogleBooksSearchResult]) {
        self.searchText = searchText
        self.searchResults = results
    }
    
    static func empty(searchText: String) -> GoogleBooksSearchResultPage {
        return GoogleBooksSearchResultPage(searchText: searchText, results: [])
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
