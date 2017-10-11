//
//  ExportViewController.swift
//  books
//
//  Created by Andrew Bennet on 05/08/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import Crashlytics
import SVProgressHUD

class ExportViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(footer: """
            Tap the button to export all books to a CSV file. CSV files can be opened by most spreadsheet software.

            The CSV file will have the following headers:

            \(Book.csvColumnHeaders.map{ "  \u{2022} \($0)" }.joined(separator: "\n"))
            """)
            <<< ButtonRow() {
                $0.title = "Export"
                $0.onCellSelection{ [unowned self] cell,_ in
                    self.exportData()
                }
            }
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
