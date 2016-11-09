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
        navigationItem.title = bookMetadata.title
        
        super.viewDidLoad()
        
        // Set the read state on the form; add some default form values for the dates
        readState = bookReadingInformation.readState
        startedReading = Date()
        finishedReading = Date()
    }
    
    @IBAction func doneWasPressed(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it.
        // Ignore the dates which are not relevant.
        bookReadingInformation.readState = readState
        bookReadingInformation.startedReading = readState == .toRead ? nil : startedReading
        bookReadingInformation.finishedReading = readState != .finished ? nil : finishedReading
        appDelegate.booksStore.create(from: bookMetadata, readingInformation: bookReadingInformation)
        appDelegate.booksStore.save()
        
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func onChange() {
        doneButton.isEnabled = isValid
    }
}
