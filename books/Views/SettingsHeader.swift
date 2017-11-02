//
//  SettingsHeader.swift
//  books
//
//  Created by Andrew Bennet on 29/10/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class SettingsHeader: UIView {
    @IBOutlet weak var versionNumber: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        versionNumber.text = "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)"
    }
}
