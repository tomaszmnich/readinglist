//
//  BookImport.swift
//  books
//
//  Created by Andrew Bennet on 20/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import SwiftyJSON
import CSVImporter

class BookImport {
    
    /// Callback sends imported count, duplicate count, and invalid count.
    static func importFrom(csvFile: URL, supplementBooks: Bool, callback: @escaping (Int, Int, Int) -> Void) {
        let importer = CSVImporter<(BookMetadata, BookReadingInformation)?>(path: csvFile.path, workQosClass: .userInitiated)
        
        let importResults = importer.importRecords(structure: { headers in
            // TODO: Ideally we could throw an error and not import the document if there are bad rows...
            if !headers.contains("Title") || !headers.contains("Author") {
                print("Missing Title or Author column")
            }
        }, recordMapper: BookMetadata.csvImport)
        
        let validEntries = importResults.flatMap{ $0 }
        let deduplicatedEntries = validEntries.filter {
            appDelegate.booksStore.getIfExists(googleBooksId: $0.0.googleBooksId, isbn: $0.0.isbn13) == nil
        }
        
        // Grab the current maximum sort, so that we can add the new books after it
        var sortIndex = appDelegate.booksStore.maxSort() ?? -1
        
        // Keep track of the potentially numerous calls
        let dispatchGroup = DispatchGroup()
        for entry in deduplicatedEntries {
            dispatchGroup.enter()
            
            // Increment the sort index if this is a ToRead book.
            let specifiedSort: Int?
            if entry.1.readState == .toRead {
                sortIndex += 1
                specifiedSort = sortIndex
            }
            else {
                specifiedSort = nil
            }

            if supplementBooks {
                supplementBook(entry.0, readingInfo: entry.1) {
                    DispatchQueue.main.async {
                        appDelegate.booksStore.create(from: entry.0, readingInformation: entry.1, bookSort: specifiedSort)
                        dispatchGroup.leave()
                    }
                }
            }
            else {
                appDelegate.booksStore.create(from: entry.0, readingInformation: entry.1, bookSort: specifiedSort)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            callback(deduplicatedEntries.count, validEntries.count - deduplicatedEntries.count, importResults.count - validEntries.count)
        }
    }
    
    static func supplementBook(_ bookMetadata: BookMetadata, readingInfo: BookReadingInformation, callback: @escaping (Void) -> Void) {
        
        func getCoverCallback(coverResult: Result<Data>) {
            if coverResult.isSuccess {
                bookMetadata.coverImage = coverResult.value!
            }
            callback()
        }
        
        // GoogleBooks ID takes priority over ISBN.
        if let googleBookdId = bookMetadata.googleBooksId {
            GoogleBooks.getCover(googleBooksId: googleBookdId, callback: getCoverCallback)
        }
            // but we'll try the ISBN is there was no Google Books ID
            // TODO: would be nice to supplement with GBID too
        else if let isbn = bookMetadata.isbn13 {
            GoogleBooks.getCover(isbn: isbn, callback: getCoverCallback)
        }
        else if let coverUrl = bookMetadata.coverUrl {
            GoogleBooks.requestData(from: coverUrl, callback: getCoverCallback)
        }
        else {
            callback()
        }
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
            addData(data)
        }
    }
    
    private static func convertToCsvLine(_ cellValues: [String]) -> String {
        return cellValues.map{ $0.toCsvEscaped() }.joined(separator: ",") + "\n"
    }
    
    func write(to fileURL: URL) throws {
        try document.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
