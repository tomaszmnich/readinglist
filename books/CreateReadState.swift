//
//  CreateReadState.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class CreateReadState: ReadStateForm {

    var bookMetadata: BookMetadata!
    var bookReadingInformation = BookReadingInformation()
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        // Set the read state on the info
        bookReadingInformation.readState = (self.navigationController as! NavWithReadState).readState
        
        super.viewDidLoad()
        
        // Set the read state on the form; add some default form values for the dates
        ReadState = bookReadingInformation.readState
        StartedReading = NSDate()
        FinishedReading = NSDate()
    }
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it.
        // Ignore the dates which are not relevant.
        bookReadingInformation.readState = ReadState
        bookReadingInformation.startedReading = ReadState == .ToRead ? nil : StartedReading
        bookReadingInformation.finishedReading = ReadState != .Finished ? nil : FinishedReading
        appDelegate.booksStore.CreateBook(bookMetadata, readingInformation: bookReadingInformation)
        appDelegate.booksStore.Save()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func OnChange() {
        doneButton.enabled = IsValid()
    }
}