//
//  Settings.swift
//  books
//
//  Created by Andrew Bennet on 23/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Foundation

class Settings: UITableViewController {

    @IBOutlet weak var addTestDataCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !DEBUG
        addTestDataCell.isHidden = true
        #endif
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            TestData.loadTestData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
