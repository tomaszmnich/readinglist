//
//  iCloudSyncViewController.swift
//  books
//
//  Created by Andrew Bennet on 25/09/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka

class iCloudSyncViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(footer: "Enable iCloud Sync to automatically synchronise changes between your iOS devices")
            <<< SwitchRow() {
                $0.title = "iCloud Sync"
                $0.value = UserSettings.iCloudSync
            }.onChange {
                UserSettings.iCloudSync = $0.value ?? false
            }
    }
}
