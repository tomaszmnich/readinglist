//
//  PrivacyViewController.swift
//  books
//
//  Created by Andrew Bennet on 11/10/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka
import UIKit

class PrivacyViewController: FormViewController {
    private let sendAnalyticsKey = "sendAnalytics"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(header: "Analytics", footer: "Anonymous usage statistics and crash reports can be reported to help improve Reading List.")
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
    }
    
    func analyticsPersuation() {
        let alert = UIAlertController(title: "Turn off analytics?", message: "Anonymous usage statistics and crash reports help prioritise development. These never include any information about your books. Are you sure you want to turn this off?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Turn Off", style: .destructive))
        alert.addAction(UIAlertAction(title: "Leave On", style: .default) { [unowned self] _ in
            // Switch it back on
            let switchRow = self.form.rowBy(tag: self.sendAnalyticsKey) as! SwitchRow
            switchRow.value = true
            switchRow.updateCell()
        })
        present(alert, animated: true)
    }
}
