//
//  ImportExport.swift
//  books
//
//  Created by Andrew Bennet on 20/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON

// TODO: remove JSON import, replace with native CSV import
class BookImport {
    
    static func fromJson(_ json: JSON) -> (BookMetadata, BookReadingInformation) {
        let bookMetadata = BookMetadata()
        bookMetadata.title = json["title"].stringValue
        bookMetadata.authorList = json["author"].stringValue
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

class CsvColumn<TData> {
    let header: String
    let cellValue: (TData) -> String?
    
    init(header: String, cellValue: @escaping (TData) -> String?) {
        self.header = header
        self.cellValue = cellValue
    }
}

class CsvExport<TData> {
    let columns: [CsvColumn<TData>]
    
    init(columns: CsvColumn<TData>...) {
        self.columns = columns
    }
    
    func headers() -> [String] {
        return columns.map{$0.header}
    }
    
    func cellValues(data: TData) -> [String] {
        return columns.map{$0.cellValue(data) ?? ""}
    }
}

class CsvExporter<TData> {
    let csvExport: CsvExport<TData>
    private var document: String
    
    init(csvExport: CsvExport<TData>){
        self.csvExport = csvExport
        document = CsvExporter.convertToCsvLine(csvExport.headers())
    }
    
    func addData(_ data: TData) {
        document.append(CsvExporter.convertToCsvLine(csvExport.cellValues(data: data)))
    }
    
    func addData(_ dataArray: [TData]) {
        for data in dataArray {
            document.append(CsvExporter.convertToCsvLine(csvExport.cellValues(data: data)))
        }
    }
    
    private static func convertToCsvLine(_ cellValues: [String]) -> String {
        return cellValues.map{$0.toCsvEscaped()}.joined(separator: ",") + "\n"
    }
    
    func write(to fileURL: URL) throws {
        print(document)
        try document.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
