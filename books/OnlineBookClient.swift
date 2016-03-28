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
            if(result != nil){
                // We have a result, so make a Book and populate it
                book = appDelegate.booksStore.CreateBook()
                
                // Attach some values which do not necessarily come from the online source
                book!.readState = readState
                book!.isbn13 = isbn13
                
                // Parse the online response
                TParser.parseJsonResponseIntoBook(book!, jResponse: result!)
                
                // If there was an image URL in the result, request that too
                if let dataUrl = book!.coverUrl {
                    HttpClient.GetData(dataUrl, callback: BookCoverImageCallback)
                }
                else{
                    SaveAndIndexAndCallback()
                }
            }
        }
        
        func BookCoverImageCallback(coverData: NSData?){
            if coverData != nil{
                book!.coverImage = coverData
            }
            SaveAndIndexAndCallback()
        }
        
        func SaveAndIndexAndCallback(){
            appDelegate.booksStore.Save()
            if book != nil {
                appDelegate.booksStore.IndexBookInSpotlight(book!)
            }
            completionHandler(book)
        }
        
        HttpClient.GetJson(searchUrl, callback: InitalSearchResultCallback)
    }
}
