//
//  ImportDataViewController.swift
//  books
//
//  Created by Andrew Bennet on 08/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import SVProgressHUD
import CSVImporter

class ImportDataViewController : FormViewController, UIDocumentPickerDelegate, UIDocumentMenuDelegate {
    
    private let downloadImagesKey = "downloadImages"
    private let selectDocumentKey = "selectDocument"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let downloadImagesSection = Section(footer: "If enabled, book covers will be downloaded where the import document has either an ISBN-13 or a Google Books ID.")
        downloadImagesSection.append(SwitchRow(downloadImagesKey) {
            $0.title = "Download Images"
            $0.value = true
        })
        form.append(downloadImagesSection)
        
        let selectDocumentSection = Section(footer: "Import books from a CSV file.")
        selectDocumentSection.append(ButtonRow(selectDocumentKey) {
            $0.title = "Import Books"
            $0.onCellSelection(self.requestImport)
        })
        form.append(selectDocumentSection)
    }
    
    func requestImport(cell: ButtonCellOf<String>, row: ButtonRow) {
        let documentImport = UIDocumentMenuViewController(documentTypes: ["public.comma-separated-values-text"], in: .import)
        documentImport.delegate = self
        if let popPresenter = documentImport.popoverPresentationController {
            popPresenter.sourceRect = cell.contentView.bounds
            popPresenter.sourceView = cell.contentView
            popPresenter.permittedArrowDirections = .up
        }
        self.present(documentImport, animated: true)
    }
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        SVProgressHUD.show(withStatus: "Importing")
        
        // We may want to download book cover images
        let shouldSupplementBooks = form.values()[downloadImagesKey] as! Bool
        
        let importer = CSVImporter<(BookMetadata, BookReadingInformation)?>(path: url.path, workQosClass: .userInitiated)
        
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
        
        // Keep track of the potentially numerous calls
        let dispatchGroup = DispatchGroup()
        for entry in deduplicatedEntries {
            dispatchGroup.enter()
            
            if shouldSupplementBooks {
                supplementBook(entry.0, readingInfo: entry.1) {
                    DispatchQueue.main.async {
                        appDelegate.booksStore.create(from: entry.0, readingInformation: entry.1)
                        dispatchGroup.leave()
                    }
                }
            }
            else {
                appDelegate.booksStore.create(from: entry.0, readingInformation: entry.1)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            var statusMessage = "\(deduplicatedEntries.count) books imported."
            
            let duplicateCount = validEntries.count - deduplicatedEntries.count
            if duplicateCount != 0 {
                statusMessage += " \(duplicateCount) rows ignored due pre-existing data."
            }

            let invalidDataCount = importResults.count - validEntries.count
            if invalidDataCount != 0 {
                statusMessage += " \(invalidDataCount) rows ignored due to invalid data."
            }
            SVProgressHUD.showInfo(withStatus: statusMessage)
        }
    }
    
    func supplementBook(_ bookMetadata: BookMetadata, readingInfo: BookReadingInformation, callback: @escaping (Void) -> Void) {
        
        func getCoverCallback(coverResult: Result<Data?>) {
            if coverResult.isSuccess, let coverImage = coverResult.value! {
                bookMetadata.coverImage = coverImage
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
        else {
            callback()
        }
    }
}
