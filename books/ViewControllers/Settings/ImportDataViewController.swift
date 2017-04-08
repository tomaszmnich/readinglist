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
            $0.value = false
            $0.disabled = Condition(booleanLiteral: true)
        })
        form.append(downloadImagesSection)
        
        let selectDocumentSection = Section(footer: "Import books from a CSV file.")
        selectDocumentSection.append(ButtonRow(selectDocumentKey) {
            $0.title = "Select Document"
            $0.onCellSelection(self.requestImport)
        })
        form.append(selectDocumentSection)
    }
    
    func requestImport(cell: ButtonCellOf<String>, row: ButtonRow) {
        let documentImport = UIDocumentMenuViewController.init(documentTypes: ["public.comma-separated-values-text"], in: .import)
        documentImport.delegate = self
        self.present(documentImport, animated: true)
    }
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        SVProgressHUD.show(withStatus: "Importing")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let importer = CSVImporter<(BookMetadata?, BookReadingInformation?)>(path: url.path, workQosClass: .userInitiated)
            let importResults = importer.importRecords(structure: { headers in
                if !headers.contains("Title") || !headers.contains("Author") {
                    print("Missing Title or Author column")
                }
            }, recordMapper: BookMetadata.csvImport)
            
            DispatchQueue.main.async {
                var duplicateBookCount = 0
                var invalidDataCount = 0
                var createdBooksCount = 0
                for importResult in importResults {
                    if let bookMetadata = importResult.0, let readingInfo = importResult.1 {
                        
                        if appDelegate.booksStore.getIfExists(googleBooksId: bookMetadata.googleBooksId, isbn: bookMetadata.isbn13) != nil {
                            duplicateBookCount += 1
                        }
                        else {
                            appDelegate.booksStore.create(from: bookMetadata, readingInformation: readingInfo)
                            createdBooksCount += 1
                        }
                    }
                    else {
                        invalidDataCount += 1
                    }
                }
                
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
    }
}
