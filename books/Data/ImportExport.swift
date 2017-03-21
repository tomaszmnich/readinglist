//
//  ImportExport.swift
//  books
//
//  Created by Andrew Bennet on 20/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON

class BookImport {
    
    static func fromJson(_ json: JSON) -> (BookMetadata, BookReadingInformation) {
        let bookMetadata = BookMetadata()
        bookMetadata.title = json["title"].stringValue
        bookMetadata.authorList = json["authors"].stringValue
        bookMetadata.bookDescription = json["description"].string
        if let coverUrlString = json["coverUrl"].string {
            bookMetadata.coverUrl = URL(string: coverUrlString)
        }
        
        var startedWhen: Date? = nil, finishedWhen: Date? = nil
        if let startedString = json["started"].string {
            startedWhen = Date(dateString: startedString)
        }
        if let finishedString = json["finished"].string {
            finishedWhen = Date(dateString: finishedString)
        }
        
        let bookReadingInformation: BookReadingInformation
        if finishedWhen != nil {
            bookReadingInformation = BookReadingInformation.finished(started: startedWhen!, finished: finishedWhen!)
        }
        else if startedWhen != nil {
            bookReadingInformation = BookReadingInformation.reading(started: startedWhen!)
        }
        else {
            bookReadingInformation = BookReadingInformation.toRead()
        }
        
        return (bookMetadata, bookReadingInformation)
    }
}
