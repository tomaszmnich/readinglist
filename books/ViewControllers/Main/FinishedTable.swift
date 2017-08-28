//
//  FinishedTable.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class FinishedTable: BookTable {

    override func viewDidLoad() {
        readStates = [.finished]
        navigationItem.title = "Finished"
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return rowActionsForBookInState(.finished)
    }
    
    override func footerText() -> String? {
        guard let finishedSectionIndex = self.sectionIndex(forReadState: .finished) else { return nil }
        
        let finishedCount = tableView(tableView, numberOfRowsInSection: finishedSectionIndex)
        return "Finished: \(finishedCount) book\(finishedCount == 1 ? "" : "s")"
    }
}
