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
        
        super.viewDidLoad()
    }
}
