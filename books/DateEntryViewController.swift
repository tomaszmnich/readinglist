//
//  DateEntryViewController.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class DateEntryViewController: UIViewController{

    var book: Book!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        datePicker.maximumDate = NSDate()
    }
    
    @IBAction func doneWasPressed(sender: UIButton) {
        book.finishedReading = datePicker.date
        appDelegate.booksStore.Save()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}