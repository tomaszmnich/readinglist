//
//  General.swift
//  books
//
//  Created by Andrew Bennet on 04/11/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class General: UITableViewController {
    
    @IBOutlet weak var useLargeTitlesSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            useLargeTitlesSwitch.isOn = UserSettings.useLargeTitles.value
        }
        else {
            useLargeTitlesSwitch.isOn = false
            useLargeTitlesSwitch.isEnabled = false
        }
    }
    
    @IBAction func useLargeTitlesChanged(_ sender: UISwitch) {
        UserSettings.useLargeTitles.value = sender.isOn
    }
}
