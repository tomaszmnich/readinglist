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
        let shouldDownloadBookCovers = form.values()[downloadImagesKey] as! Bool
        
        let importer = CSVImporter<(BookMetadata?, BookReadingInformation?)>(path: url.path, workQosClass: .userInitiated)
        
        let importResults = importer.importRecords(structure: { headers in
            // TODO: Ideally we could throw an error and not import the document if there are bad rows...
            if !headers.contains("Title") || !headers.contains("Author") {
                print("Missing Title or Author column")
            }
        }, recordMapper: BookMetadata.csvImport)
        
        // Keep track of the potentially numerous calls
        let dispatchGroup = DispatchGroup()
                
        var duplicateBookCount = 0
        var invalidDataCount = 0
        var createdBooksCount = 0
        
        dispatchGroup.enter()
        for importResult in importResults {
            guard let bookMetadata = importResult.0, let readingInfo = importResult.1 else { invalidDataCount += 1; continue }
            
            guard appDelegate.booksStore.getIfExists(googleBooksId: bookMetadata.googleBooksId, isbn: bookMetadata.isbn13) == nil else {
                duplicateBookCount += 1
                continue
            }
            
            if shouldDownloadBookCovers {
                trySupplementBookMetadataWithCover(bookMetadata, readingInfo: readingInfo, webCallsDispatchGroup: dispatchGroup)
            }
            else {
                appDelegate.booksStore.create(from: bookMetadata, readingInformation: readingInfo)
            }
            createdBooksCount += 1
        }
        dispatchGroup.leave()
        
        dispatchGroup.notify(queue: .main) {
            var statusMessage = "\(createdBooksCount) books imported."
            if duplicateBookCount != 0 {
                statusMessage += " \(duplicateBookCount) rows ignored due pre-existing data."
            }
            if invalidDataCount != 0 {
                statusMessage += " \(invalidDataCount) rows ignored due to invalid data."
            }
            SVProgressHUD.showInfo(withStatus: statusMessage)
        }
    }
    
    func trySupplementBookMetadataWithCover(_ bookMetadata: BookMetadata, readingInfo: BookReadingInformation, webCallsDispatchGroup dispatchGroup: DispatchGroup) {
        // GoogleBooks ID takes priority over ISBN.
        if let googleBookdId = bookMetadata.googleBooksId {
            dispatchGroup.enter()
            GoogleBooksAPI.getCover(googleBooksId: googleBookdId) { result in
                DispatchQueue.main.async {
                    bookMetadata.coverImage = result.successValue
                    appDelegate.booksStore.create(from: bookMetadata, readingInformation: readingInfo)
                    dispatchGroup.leave()
                }
            }
        }
            // but we'll try the ISBN is there was no Google Books ID
        else if let isbn = bookMetadata.isbn13 {
            dispatchGroup.enter()
            GoogleBooksAPI.fetchIsbn(isbn) { result in
                
                // If there was no Google Books ID for the ISBN search, then we can't get a cover.
                guard let googleBooksId = result.successValue??.googleBooksId else { dispatchGroup.leave(); return }
                
                GoogleBooksAPI.getCover(googleBooksId: googleBooksId){ coverResult in
                    DispatchQueue.main.async {
                        bookMetadata.coverImage = coverResult.successValue
                        appDelegate.booksStore.create(from: bookMetadata, readingInformation: readingInfo)
                        dispatchGroup.leave()
                    }
                }
            }
        }
    }
}
