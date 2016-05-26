//
//  CreateReadState.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class CreateReadState: ChangeReadState {

    var bookMetadata: BookMetadata!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the existing values on to the form when it's about to appear
        setValues(ReadStatePageInputs(readState: bookMetadata.readState, dateStarted: bookMetadata.startedReading, dateFinished: bookMetadata.finishedReading))
    }
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it
        let formValues = getValues()
        bookMetadata.readState = formValues.readState
        bookMetadata.startedReading = formValues.dateStarted
        bookMetadata.finishedReading = formValues.dateFinished
        appDelegate.booksStore.CreateBook(bookMetadata)
        appDelegate.booksStore.Save()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}