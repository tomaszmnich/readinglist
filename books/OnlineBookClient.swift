//
//  OnlineBooksClient.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON

class OnlineBookClient<TParser: BookParser>{
    
    static func TryCreateBook(searchUrl: String, readState: BookReadState, isbn13: String, completionHandler: (Book? -> Void)){
        var book: Book?
        
        func InitalSearchResultCallback(result: JSON?) {
            if let result = result {
                // We have a result, so make a Book and populate it
                book = appDelegate.booksStore.CreateBook()
                
                // Parse the online response. If it was not valid, set book back to nil
                if !TParser.parseJsonResponseIntoBook(book!, jResponse: result){
                    book = nil
                }
                else{
                    let book = book!
                    
                    // Attach some values which do not necessarily come from the online source
                    book.readState = readState
                    book.isbn13 = isbn13
                    
                    // If there was an image URL in the result, request that too
                    if let dataUrl = book.coverUrl {
                        HttpClient.GetData(dataUrl, callback: BookCoverImageCallback)
                    }
                    else{
                        SaveAndIndexAndCallback()
                    }
                }
            }
            else{
                completionHandler(book)
            }
        }
        
        func BookCoverImageCallback(coverData: NSData?){
            if let coverData = coverData {
                book!.coverImage = coverData
            }
            SaveAndIndexAndCallback()
        }
        
        func SaveAndIndexAndCallback(){
            appDelegate.booksStore.SaveAndUpdateIndex(book!)
            completionHandler(book)
        }
        
        HttpClient.GetJson(searchUrl, callback: InitalSearchResultCallback)
    }
}
