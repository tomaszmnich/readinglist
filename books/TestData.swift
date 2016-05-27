//
//  TestData.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class TestData {
    
    static func loadDefaultDataIfFirstLaunch() {
        let key = "hasLaunchedBefore"
        let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey(key)
        if launchedBefore == false {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
            
            let booksToAdd: [(isbn: String, readState: BookReadState, started: NSDate?, finished: NSDate?)] = [
                ("9781847924032", .Reading, NSDate(dateString: "2016-04-27"), nil), //And The Weak Suffer What They Must?
                ("9780099889809", .Reading, NSDate(dateString: "2015-12-20"), nil), //Something Happened
                ("9780007532766", .Finished, NSDate(dateString: "2015-08-26"), NSDate(dateString: "2015-10-25")), //Purity
                ("9780857059994", .Finished, NSDate(dateString: "2016-01-12"), NSDate(dateString: "2016-02-23")), //The Girl in the Spider's web
                ("9781476781105", .Reading, NSDate(dateString: "2016-05-14"), nil), //Shards of Honor
                ("978751549256", .ToRead, nil, nil) //The Cuckoo's Calling
            ]
            
            for bookToAdd in booksToAdd {
                OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(GoogleBooksRequest.Search(bookToAdd.isbn).url, completionHandler: {
                    if let bookMetadata = $0 {
                        bookMetadata.isbn13 = bookToAdd.isbn
                        let readingInfo = BookReadingInformation()
                        readingInfo.readState = bookToAdd.readState
                        readingInfo.startedReading = bookToAdd.started
                        readingInfo.finishedReading = bookToAdd.finished
                        appDelegate.booksStore.CreateBook(bookMetadata, readingInformation: readingInfo)
                    }
                })
            }
        }
    }
}