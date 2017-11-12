//
//  About.swift
//  books
//
//  Created by Andrew Bennet on 04/11/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class About: UITableViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://www.readinglistapp.xyz")!)
        case (0, 2):
            UIApplication.shared.openUrlPlatformSpecific(url: URL(string: "https://github.com/AndrewBennet/readinglist")!)
        case (0, 3):
            share()
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func share() {
        let activityViewController = UIActivityViewController(activityItems: [URL(string: "https://\(Settings.appStoreAddress)")!], applicationActivities: nil)
        if let popPresenter = activityViewController.popoverPresentationController {
            let cell = self.tableView.cellForRow(at: IndexPath(row: 2, section: 0))!
            popPresenter.sourceRect = cell.frame
            popPresenter.sourceView = self.tableView
            popPresenter.permittedArrowDirections = .any
        }
        present(activityViewController, animated: true)
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

