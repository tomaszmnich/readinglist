//
//  EditReadState.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class EditReadState: ChangeReadState {
    
    var bookToEdit: Book!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!

    override func viewDidLoad(){
        super.viewDidLoad()
        
        navigationItem.title = bookToEdit.title
        
        // Load the existing values on to the form when it's about to appear
        setValues(ReadStatePageInputs(readState: bookToEdit.readState, dateStarted: bookToEdit.startedReading, dateFinished: bookToEdit.finishedReading))
    }
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it
        let formValues = getValues()
        bookToEdit.readState = formValues.readState!
        if bookToEdit.readState != .ToRead {
            bookToEdit.startedReading = formValues.dateStarted
        }
        if bookToEdit.readState == .Finished {
            bookToEdit.finishedReading = formValues.dateFinished
        }
        appDelegate.booksStore.UpdateSpotlightIndex(bookToEdit)
        appDelegate.booksStore.Save()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelWasPressed(sender: UIBarButtonItem) {
        // Just exit
        self.view.endEditing(true)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}