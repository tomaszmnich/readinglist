//
//  Settings.swift
//  books
//
//  Created by Andrew Bennet on 23/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Foundation
import SVProgressHUD
import SwiftyJSON

class Settings: UITableViewController, NavBarConfigurer {
    
    var navBarChangedDelegate: NavBarChangedDelegate!

    @IBOutlet weak var addTestDataCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !DEBUG
        addTestDataCell.isHidden = true
        #endif
    }
    
    func configureNavBar(_ navBar: UINavigationItem) {
        // Configure the navigation item
        navBar.title = "Settings"
        navBar.rightBarButtonItem = nil
        navBar.leftBarButtonItem = nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // "About"
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://andrewbennet.github.io/readinglist")!) 
        case (0, 2):
            // "Rate"
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "itms-apps://itunes.apple.com/app/\(appleAppId)")!)
        
        case (1, 0):
            exportData()
        case (1, 1):
            // "Use Test Data"
            #if DEBUG
                loadTestData()
            #endif
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func exportData() {
        SVProgressHUD.show(withStatus: "Generating...")
        
        DispatchQueue.main.async {
            // Generate the CSV Document in memory
            let exporter = CsvExporter(csvExport: Book.csvExport)
            for book in appDelegate.booksStore.get(fetchRequest: appDelegate.booksStore.bookFetchRequest()) {
                exporter.addData(data: book)
            }
            
            // Write the document to a temporary file
            let exportFileName = "Reading List Export - \(Date().toString(withDateFormat: "yyyy-MM-dd hh-mm")).csv"
            let temporaryFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(exportFileName)
            do {
                try exporter.write(to: temporaryFilePath)
            }
            catch {
                NSLog(error.localizedDescription)
                SVProgressHUD.dismiss()
                SVProgressHUD.showInfo(withStatus: "An error occurred.")
                return
            }
            
            // Present a dialog with the resulting file
            let activityViewController = UIActivityViewController(activityItems: [temporaryFilePath], applicationActivities: [])
            activityViewController.excludedActivityTypes = [
                UIActivityType.assignToContact,
                UIActivityType.saveToCameraRoll,
                UIActivityType.postToFlickr,
                UIActivityType.postToVimeo,
                UIActivityType.postToTencentWeibo,
                UIActivityType.postToTwitter,
                UIActivityType.postToFacebook,
                UIActivityType.openInIBooks
            ]
            
            SVProgressHUD.dismiss()
            self.present(activityViewController, animated: true, completion: nil)
        }
    }


    #if DEBUG
    func loadTestData() {

        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        let testJsonData = JSON(data: NSData.fromMainBundle(resource: "example_books", type: "json") as Data)
        appDelegate.booksStore.deleteAllData()
        
        let requestDispatchGroup = DispatchGroup()
        var sortIndex = -1
        
        for testBook in testJsonData.array! {
            let parsedData = BookImport.fromJson(testBook)
            
            if parsedData.1.readState == .toRead {
                sortIndex += 1
            }
            let thisSort = sortIndex
            
            requestDispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                GoogleBooksAPI.supplementMetadataWithImage(parsedData.0) {
                    DispatchQueue.main.sync {
                        appDelegate.booksStore.create(from: parsedData.0, readingInformation: parsedData.1, bookSort: thisSort)
                        requestDispatchGroup.leave()
                    }
                }
            }
        }

        requestDispatchGroup.notify(queue: .main) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    #endif
}
