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
    @IBOutlet weak var deleteAllDataCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if !DEBUG
        addTestDataCell.isHidden = true
        deleteAllDataCell.isHighlighted = true
        #endif
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            TestData.loadTestData()
        }
        else if indexPath.section == 2 && indexPath.row == 1 {
            appDelegate.booksStore.deleteAllData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
