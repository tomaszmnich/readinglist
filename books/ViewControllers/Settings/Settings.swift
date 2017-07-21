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
import Crashlytics
import Fabric
import MessageUI

class Settings: UITableViewController, NavBarConfigurer, MFMailComposeViewControllerDelegate {
    
    var navBarChangedDelegate: NavBarChangedDelegate!
    
    @IBOutlet weak var debugSettingsCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
            debugSettingsCell.isHidden = false
        #else
            debugSettingsCell.isHidden = true
        #endif
    }
    
    func configureNavBar(_ navBar: UINavigationItem) {
        // Configure the navigation item
        navBar.title = "Settings"
        navBar.rightBarButtonItem = nil
        navBar.leftBarButtonItem = nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // "About"
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://andrewbennet.github.io/readinglist")!)
        case (0, 1):
            // "Rate"
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "itms-apps://appsto.re/gb/ZtbJib.i?action=write-review")!)
        case (0, 2):
            // "Feedback"
            sendFeedbackEmail()
            
        case (1, 0):
            exportData()
        case (1, 2):
            deleteAllData()
            
        case (2, 0):
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://github.com/AndrewBennet/readinglist")!)

        default:
            break
        }
    }
    
    func deleteAllData() {
        
        // The CONFIRM DELETE action:
        let confirmDelete = UIAlertController(title: "Final Warning", message: "This action is irreversible. Are you sure you want to continue?", preferredStyle: .alert)
        confirmDelete.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            appDelegate.booksStore.deleteAll()
            // Relayout the tables. Their empty data sets sometimes are in the wrong place after deleting everything.
            // TODO: look into making this work better
            appDelegate.splitViewController.tabbedViewController.readingTabView.layoutSubviews()
            appDelegate.splitViewController.tabbedViewController.finishedTabView.layoutSubviews()
        })
        confirmDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // The initial WARNING action
        let areYouSure = UIAlertController(title: "Warning", message: "This will delete all books saved in the application. Are you sure you want to continue?", preferredStyle: .alert)
        areYouSure.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.present(confirmDelete, animated: true)
        })
        areYouSure.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(areYouSure, animated: true)
    }
    
    func exportData() {
        Answers.logCustomEvent(withName: "CSV Export", customAttributes: [:])
        SVProgressHUD.show(withStatus: "Generating...")
        
        let exporter = CsvExporter(csvExport: Book.csvExport)
        
        appDelegate.booksStore.getAllBooksAsync(callback: {
            exporter.addData($0)
            self.renderAndServeCsvExport(exporter)
        }, onFail: {
            NSLog($0.localizedDescription)
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "Error collecting data.")
        })
    }
    
    func renderAndServeCsvExport(_ exporter: CsvExporter<Book>) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            // Write the document to a temporary file
            let exportFileName = "Reading List Export - \(Date().toString(withDateFormat: "yyyy-MM-dd hh-mm")).csv"
            let temporaryFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(exportFileName)
            do {
                try exporter.write(to: temporaryFilePath)
            }
            catch {
                NSLog(error.localizedDescription)
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
                let cellRect = self.tableView.rectForRow(at: IndexPath(item: 0, section: 1))
                popPresenter.sourceRect = cellRect
                popPresenter.sourceView = self.tableView
                popPresenter.permittedArrowDirections = .any
            }
            
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func sendFeedbackEmail() {
        let toEmail = "readinglist@andrewbennet.com"
        if MFMailComposeViewController.canSendMail() {

            let appDisplayVersion: String
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"],
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] {
                appDisplayVersion = "v\(appVersion) (\(buildVersion))"
            }
            else {
                appDisplayVersion = "Unknown"
            }
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([toEmail])
            mailComposer.setSubject("Reading List \(appDisplayVersion) Feedback")
            let messageBody = "\n\n\n" +
                "Reading List\n" +
                "App Version: \(appDisplayVersion)\n" +
                "iOS Version: \(UIDevice.current.systemVersion)\n" +
                "Device: \(UIDevice.current.model)"
            mailComposer.setMessageBody(messageBody, isHTML: false)
            self.present(mailComposer, animated: true)
        }
        else {
            let alert = UIAlertController(title: "Can't send email", message: "Couldn't find any email accounts. If you *really* want to give feedback, email \(toEmail). Thanks!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true)
    }
}
