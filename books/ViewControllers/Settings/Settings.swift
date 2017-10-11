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
import Eureka

class Settings: FormViewController, MFMailComposeViewControllerDelegate {
    
    let appStoreAddress = "itunes.apple.com/gb/app/reading-list-book-tracker/id1217139955"
    private let bookSortOrderKey = "sortOrder"
    private let sendAnalyticsKey = "sendAnalytics"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(header: "General", footer: "If you find Reading List useful, please consider giving it a rating. If you have any suggestions, feedback is welcome 👍")
            <<< ActionButton(title: "📚 About", url: URL(string: "https://www.readinglistapp.xyz")!)
            <<< ActionButton(title: "👋 Share", action: self.share)
            <<< ActionButton(title: "❤️ Rate", url: URL(string: "itms-apps://\(self.appStoreAddress)?action=write-review")!)
            <<< ActionButton(title: "💡 Feedback", action: self.sendFeedbackEmail)
        
        +++ Section(header: "Options", footer: "")
            <<< NavigationRow(title: "Book Sort Order", segueName: "sortOrder", initialiser: { [unowned self] row in
                row.cellStyle = .value1
                row.tag = self.bookSortOrderKey
            }) { cell, _ in
                cell.detailTextLabel!.text = UserSettings.tableSortOrder.displayName
            }
        
        +++ Section(header: "Data", footer: "")
            <<< NavRow<ImportViewController>(title: "Import")
            <<< NavRow<ExportViewController>(title: "Export")
            <<< ActionButton(title: "Delete All", action: self.deleteAllData) { cell, _ in
                cell.textLabel?.textColor = .red
            }
            
        +++ Section(header: "Privacy", footer: "To help improve this app, Reading List sends some anonymous usage statistics and crash reports.")
            <<< SwitchRow() {
                $0.tag = sendAnalyticsKey
                $0.title = "Send Analytics"
                $0.value = UserSettings.sendAnalytics.value
                $0.onChange { [weak self] row in
                    UserSettings.sendAnalytics.value = row.value!
                    if row.value! {
                        UserEngagement.logEvent(.enableAnalytics)
                    }
                    else {
                        // If this is being turned off, let's try to persuade them to turn it back on
                        UserEngagement.logEvent(.disableAnalytics)
                        self?.analyticsPersuation()
                    }
                }
            }
        
        +++ Section(header: "Open Source", footer: "Reading List v\(appDelegate.appVersion)\nDeveloped by Andrew Bennet")
            <<< ActionButton(title: "View Source Code", url: URL(string: "https://github.com/AndrewBennet/readinglist")!)
            <<< NavigationRow(title: "Attributions", segueName: "attributions")
        
        #if DEBUG
            form.allSections.last! <<< NavRow<DebugSettingsViewController>(title: "Debug Settings")
        #endif
    
        // Watch for changes in book sort order
        NotificationCenter.default.addObserver(self, selector: #selector(bookSortChanged), name: NSNotification.Name.onBookSortOrderChanged, object: nil)
    }
    
    func analyticsPersuation() {
        let alert = UIAlertController(title: "Turn off analytics?", message: "Reading List sends some anonymous usage statistics to helps me prioritise development. This never includes any information about your books.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Turn Off", style: .destructive))
        alert.addAction(UIAlertAction(title: "Leave On", style: .default) { [unowned self] _ in
            // Switch it back on
            let switchRow = self.form.rowBy(tag: self.sendAnalyticsKey) as! SwitchRow
            switchRow.value = true
            switchRow.updateCell()
        })
        present(alert, animated: true)
    }

    @objc func bookSortChanged() {
        form.rowBy(tag: bookSortOrderKey)!.updateCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // Center the first and last footer
        guard section == 0 || section == 4 else { return }
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textAlignment = .center
        }
    }
    
    func share() {
        let activityViewController = UIActivityViewController(activityItems: [URL(string: "https://\(appStoreAddress)")!], applicationActivities: nil)
        if let popPresenter = activityViewController.popoverPresentationController {
            let cell = self.tableView.cellForRow(at: IndexPath(row: 1, section: 0))!
            popPresenter.sourceRect = cell.frame
            popPresenter.sourceView = self.tableView
            popPresenter.permittedArrowDirections = .any
        }
        present(activityViewController, animated: true)
    }
    
    func deleteAllData() {
        
        // The CONFIRM DELETE action:
        let confirmDelete = UIAlertController(title: "Final Warning", message: "This action is irreversible. Are you sure you want to continue?", preferredStyle: .alert)
        confirmDelete.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            appDelegate.booksStore.deleteAll()
        })
        confirmDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // The initial WARNING action
        let areYouSure = UIAlertController(title: "Warning", message: "This will delete all books saved in the application. Are you sure you want to continue?", preferredStyle: .alert)
        areYouSure.addAction(UIAlertAction(title: "Delete", style: .destructive) { [unowned self] _ in
            self.present(confirmDelete, animated: true)
        })
        areYouSure.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(areYouSure, animated: true)
    }
    
    func sendFeedbackEmail() {
        let toEmail = "feedback@readinglistapp.xyz"
        if MFMailComposeViewController.canSendMail() {            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["Reading List Developer <\(toEmail)>"])
            mailComposer.setSubject("Reading List Feedback")
            let messageBody = """
            


            Reading List
            App Version: \(appDelegate.appVersion)
            Build Number: \(appDelegate.appBuildNumber)
            iOS Version: \(UIDevice.current.systemVersion)
            Device: \(UIDevice.current.modelIdentifier)
            """
            mailComposer.setMessageBody(messageBody, isHTML: false)
            self.present(mailComposer, animated: true)
        }
        else {
            let alert = UIAlertController(title: "Can't send email", message: "Couldn't find any email accounts. If you want to give feedback, email \(toEmail)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true)
    }
}
