//
//  Data.swift
//  books
//
//  Created by Andrew Bennet on 04/11/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD
import Fabric
import Crashlytics
import Eureka

class DataVC: UITableViewController, UIDocumentPickerDelegate, UIDocumentMenuDelegate {
    
    static let importIndexPath = IndexPath(row: 0, section: 0)
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (DataVC.importIndexPath.section, DataVC.importIndexPath.row):
            requestImport()
        case (0, 1):
            exportData()
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func requestImport() {
        let documentImport = UIDocumentMenuViewController(documentTypes: ["public.comma-separated-values-text"], in: .import)
        documentImport.delegate = self
        if let popPresenter = documentImport.popoverPresentationController {
            let cell = tableView(tableView, cellForRowAt: DataVC.importIndexPath)
            popPresenter.sourceRect = cell.frame
            popPresenter.sourceView = self.tableView
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
        
        BookImporter(csvFileUrl: url, supplementBookCover: true, missingHeadersCallback: {
            
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
    
    func exportData() {
        UserEngagement.logEvent(.csvExport)
        SVProgressHUD.show(withStatus: "Generating...")
        
        let exporter = CsvExporter(csvExport: Book.csvExport)
        
        appDelegate.booksStore.getAllBooksAsync(callback: {
            exporter.addData($0)
            self.renderAndServeCsvExport(exporter)
        }, onFail: {
            Crashlytics.sharedInstance().recordError($0)
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "Error collecting data.")
        })
    }
    
    func renderAndServeCsvExport(_ exporter: CsvExporter<Book>) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            // Write the document to a temporary file
            let exportFileName = "Reading List - \(UIDevice.current.name) - \(Date().toString(withDateFormat: "yyyy-MM-dd hh-mm")).csv"
            let temporaryFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(exportFileName)
            do {
                try exporter.write(to: temporaryFilePath)
            }
            catch {
                Crashlytics.sharedInstance().recordError(error)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showError(withStatus: "Error exporting data.")
                }
                return
            }
            
            // Present a dialog with the resulting file (presenting it on the main thread, of course)
            let activityViewController = UIActivityViewController(activityItems: [temporaryFilePath], applicationActivities: [])
            activityViewController.excludedActivityTypes = [
                UIActivityType.assignToContact, UIActivityType.saveToCameraRoll, UIActivityType.postToFlickr, UIActivityType.postToVimeo,
                UIActivityType.postToTencentWeibo, UIActivityType.postToTwitter, UIActivityType.postToFacebook, UIActivityType.openInIBooks
            ]
            
            if let popPresenter = activityViewController.popoverPresentationController {
                let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0))!
                popPresenter.sourceRect = cell.frame
                popPresenter.sourceView = self.tableView
                popPresenter.permittedArrowDirections = .any
            }
            
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
}
