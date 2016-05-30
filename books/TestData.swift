//
//  TestData.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class TestData {
    
    static let booksToAdd: [(isbn: String, readState: BookReadState, started: NSDate?, finished: NSDate?)] = [
        ("9780241197790", .Finished, NSDate(dateString: "2015-07-15"), NSDate(dateString: "2015-08-10")), //The Trial
        ("9780099800200", .Finished, NSDate(dateString: "2015-08-12"), NSDate(dateString: "2015-09-21")), //Slaughterhouse 5
        ("9781847924032", .Reading, NSDate(dateString: "2016-04-27"), nil), //And The Weak Suffer What They Must?
        ("9780099889809", .Reading, NSDate(dateString: "2015-12-20"), nil), //Something Happened
        ("9780007532766", .Finished, NSDate(dateString: "2015-08-26"), NSDate(dateString: "2015-10-25")), //Purity
        ("9780857059994", .Finished, NSDate(dateString: "2016-01-12"), NSDate(dateString: "2016-02-23")), //The Girl in the Spider's web
        ("9781476781105", .Reading, NSDate(dateString: "2016-05-14"), nil), //Shards of Honor
        ("9780751549256", .ToRead, nil, nil), //The Cuckoo's Calling
        ("9780099578512", .ToRead, nil, nil), //Midnight's Children
        ("9780141183442", .ToRead, nil, nil), //The Castle
        ("9780006546061", .ToRead, nil, nil) //Fahrenheit 451
    ]
    
    static func loadDefaultDataIfFirstLaunch() {
        
        // Only load the data if we haven't launched before
        let key = "hasLaunchedBefore"
        guard NSUserDefaults.standardUserDefaults().boolForKey(key) == false else { return }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
        
        // Search for each book and add the result
        for bookToAdd in booksToAdd {
            OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(GoogleBooksRequest.GetIsbn(bookToAdd.isbn).url, completionHandler: {
                guard let bookMetadata = $0 else { return }
                
                bookMetadata.isbn13 = bookToAdd.isbn
                let readingInfo = BookReadingInformation()
                readingInfo.readState = bookToAdd.readState
                readingInfo.startedReading = bookToAdd.started
                readingInfo.finishedReading = bookToAdd.finished
                appDelegate.booksStore.CreateBook(bookMetadata, readingInformation: readingInfo)
            })
        }
    }
}