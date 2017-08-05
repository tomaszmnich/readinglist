//
//  ImportViewController.swift
//  books
//
//  Created by Andrew Bennet on 08/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import SVProgressHUD
import Fabric
import Crashlytics

class ImportViewController : FormViewController, UIDocumentPickerDelegate, UIDocumentMenuDelegate {
    
    static let headerNames = ["Google Books ID", "ISBN-13", "Title", "Author", "Page Count", "Publication Date", "Description", "Subjects", "Started Reading", "Finished Reading", "Notes"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(footer: "Tap the button to import books from a CSV file. The CSV file should have the following headers:\n\n"
                + ImportViewController.headerNames.map{ "  \u{2022} \($0)" }.joined(separator: "\n")
                + "\n\nTitle and Author cells are mandatory. Subjects should be separated by semicolons.\n\nBook covers will be downloaded where the import document has either an ISBN-13 or a Google Books ID. Duplicates and invalid entries will be skipped.\n\nAn example input document can be obtained by saving the result of an Export.")
            <<< ButtonRow() {
                $0.title = "Select File"
                $0.onCellSelection{ [unowned self] cell,_ in
                    self.requestImport(cell: cell)
                }
            }
    }
    
    func requestImport(cell: ButtonCellOf<String>) {
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
        UserEngagement.logEvent(.csvImport)
        
        BookImporter(csvFileUrl: url, supplementBookCover: true, supplementBookMetadata: false, missingHeadersCallback: {
            
        }, callback: {
            importedCount, duplicateCount, invalidCount in
            var statusMessage = "\(importedCount) books imported."
            
            if duplicateCount != 0 {
                statusMessage += " \(duplicateCount) rows ignored due pre-existing data."
            }
            
            if invalidCount != 0 {
                statusMessage += " \(invalidCount) rows ignored due to invalid data."
            }
            SVProgressHUD.showInfo(withStatus: statusMessage)
        }).StartImport()
    }

}
