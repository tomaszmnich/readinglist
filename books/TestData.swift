//
//  TestData.swift
//  books
//
//  Created by Andrew Bennet on 27/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class TestData {
    
    static let booksToAdd: [(isbn: String, readState: BookReadState, started: Date?, finished: Date?)] = [
        ("9780241197790", .finished, Date(dateString: "2015-07-15"), Date(dateString: "2015-08-10")), //The Trial
        ("9780099800200", .finished, Date(dateString: "2015-08-12"), Date(dateString: "2015-09-21")), //Slaughterhouse 5
        ("9781847924032", .reading, Date(dateString: "2016-04-27"), nil), //And The Weak Suffer What They Must?
        ("9780099889809", .reading, Date(dateString: "2015-12-20"), nil), //Something Happened
        ("9780007532766", .finished, Date(dateString: "2015-08-26"), Date(dateString: "2015-10-25")), //Purity
        ("9780857059994", .finished, Date(dateString: "2016-01-12"), Date(dateString: "2016-02-23")), //The Girl in the Spider's web
        ("9781476781105", .reading, Date(dateString: "2016-05-14"), nil), //Shards of Honor
        ("9780751549256", .toRead, nil, nil), //The Cuckoo's Calling
        ("9780099578512", .toRead, nil, nil), //Midnight's Children
        ("9780141183442", .toRead, nil, nil), //The Castle
        ("9780006546061", .toRead, nil, nil) //Fahrenheit 451
    ]
    
    static func loadTestData() {
        
        // Search for each book and add the result
        for bookToAdd in booksToAdd {
            GoogleBooksAPI.search(isbn: bookToAdd.isbn) { bookMetadata, error in
                
                if let bookMetadata = bookMetadata?.first {
                    bookMetadata.isbn13 = bookToAdd.isbn
                    let readingInfo = BookReadingInformation()
                    readingInfo.readState = bookToAdd.readState
                    readingInfo.startedReading = bookToAdd.started
                    readingInfo.finishedReading = bookToAdd.finished
                    
                    appDelegate.booksStore.create(from: bookMetadata, readingInformation: readingInfo)
                }
            }
        }
    }
}
