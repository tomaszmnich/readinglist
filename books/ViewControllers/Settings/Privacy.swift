//
//  PrivacyViewController.swift
//  books
//
//  Created by Andrew Bennet on 11/10/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class Privacy: UITableViewController {
    
    @IBOutlet weak var sendAnalyticsSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        sendAnalyticsSwitch.isOn = UserSettings.sendAnalytics.value
    }
    
    @IBAction func analyticsSwitchChanged(_ sender: UISwitch) {
        UserSettings.sendAnalytics.value = sender.isOn
        if sender.isOn {
            UserEngagement.logEvent(.enableAnalytics)
        }
        else {
            // If this is being turned off, let's try to persuade them to turn it back on
            UserEngagement.logEvent(.disableAnalytics)
            analyticsPersuation(sender)
        }
    }

    func analyticsPersuation(_ uiSwitch: UISwitch) {
        let alert = UIAlertController(title: "Turn off analytics?", message: "Anonymous usage statistics and crash reports help prioritise development. These never include any information about your books. Are you sure you want to turn this off?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Turn Off", style: .destructive))
        alert.addAction(UIAlertAction(title: "Leave On", style: .default) { _ in
            // Switch it back on
            uiSwitch.setOn(true, animated: true)
        })
        present(alert, animated: true)
    }
}
