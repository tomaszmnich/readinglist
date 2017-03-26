//
//  FinishedTable.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class FinishedTable: BookTable, NavBarConfigurer {

    override func viewDidLoad() {
        readStates = [.finished]
        super.viewDidLoad()
    }
    
    func configureNavBar(_ navBar: UINavigationItem) {
        navBar.rightBarButtonItem = addButton
        navBar.leftBarButtonItem = anyBooksExist ? editButtonItem : nil
        navBar.title = "Finished"
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return rowActionsForBookInState(.finished)
    }
}
