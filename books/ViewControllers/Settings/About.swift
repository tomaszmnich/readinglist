//
//  About.swift
//  books
//
//  Created by Andrew Bennet on 04/11/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class About: UITableViewController, MFMailComposeViewControllerDelegate {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
            
        case (0, 0):
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://www.readinglistapp.xyz")!)
        case (0, 1):
            contact()
        case (0, 3):
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://github.com/AndrewBennet/readinglist")!)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func contact() {
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
}

class Attributions: UIViewController {
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableText.hyperlinkText("Icons8", to: URL(string: "https://icons8.com")!)
        mutableText.hyperlinkText("Eureka", to: URL(string: "https://github.com/xmartlabs/Eureka")!)
        mutableText.hyperlinkText("DZNEmptyDataSet", to: URL(string: "https://github.com/dzenbot/DZNEmptyDataSet")!)
        mutableText.hyperlinkText("SwiftyJSON", to: URL(string: "https://github.com/SwiftyJSON/SwiftyJSON")!)
        mutableText.hyperlinkText("RxSwift", to: URL(string: "https://github.com/ReactiveX/RxSwift")!)
        mutableText.hyperlinkText("SVProgressHUD", to: URL(string: "https://github.com/SVProgressHUD/SVProgressHUD")!)
        mutableText.hyperlinkText("CHCSVParser", to: URL(string: "https://github.com/davedelong/CHCSVParser")!)
        
        textView.attributedText = mutableText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.textView.contentOffset = CGPoint.zero
        super.viewWillAppear(animated)
    }
}

