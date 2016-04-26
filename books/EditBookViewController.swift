//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 10/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka
import UIKit

class EditBookViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++= TextRow()
        form +++= TextRow()
        form +++= TextRow()
    }
}