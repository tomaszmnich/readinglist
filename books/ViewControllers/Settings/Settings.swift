//
//  Settings.swift
//  books
//
//  Created by Andrew Bennet on 23/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import SVProgressHUD
import Crashlytics
import MessageUI

class Settings: UITableViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var debugSettingsCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
            debugSettingsCell.isHidden = false
        #else
            debugSettingsCell.isHidden = true
        #endif
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footer = view as! UITableViewHeaderFooterView
        footer.textLabel?.textAlignment = .center
        if section == 2 {
            footer.textLabel?.text = "Reading List \(appDelegate.appVersionDisplay())\nDeveloped by Andrew Bennet"
        }
    }

    let appStoreAddress = "appsto.re/gb/ZtbJib.i"
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            // "About"
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://www.readinglistapp.xyz")!)
        case (0, 1):
            // "Share"
            present(UIActivityViewController(activityItems: [URL(string: "https://\(appStoreAddress)")!], applicationActivities: nil), animated: true)
        case (0, 2):
            // "Rate"
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "itms-apps://\(appStoreAddress)?action=write-review")!)
        case (0, 3):
            // "Feedback"
            sendFeedbackEmail()
        
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
            // TODO: The empty data sets sometimes are in the wrong place after deleting everything.
            //appDelegate.splitViewController.tabbedViewController.readingTabView.layoutSubviews()
            //appDelegate.splitViewController.tabbedViewController.finishedTabView.layoutSubviews()
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
    
    func sendFeedbackEmail() {
        let toEmail = "readinglist@andrewbennet.com"
        if MFMailComposeViewController.canSendMail() {
            
            let appVersion = appDelegate.appVersionDisplay()
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([toEmail])
            mailComposer.setSubject("Reading List \(appVersion) Feedback")
            let messageBody = "\n\n\n" +
                "Reading List\n" +
                "App Version: \(appVersion)\n" +
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
