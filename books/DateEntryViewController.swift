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
    var completionHandler: ((book: Book) -> Void)!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        datePicker.maximumDate = NSDate()
    }
    
    @IBAction func doneWasPressed(sender: UIButton) {
        //todo: check whether this threading is needed
        dispatch_async(dispatch_get_main_queue()){
            self.book.finishedReading = self.datePicker.date
            appDelegate.booksStore.SaveAndUpdateIndex(self.book)
            self.dismissViewControllerAnimated(true, completion: {
                self.completionHandler(book: self.book)
            })
        }
    }
}