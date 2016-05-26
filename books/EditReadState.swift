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
        ReadState = bookToEdit.readState
        StartedReading = bookToEdit.startedReading
        FinishedReading = bookToEdit.finishedReading
    }
    
    override func OnChange() {
        doneButton.enabled = IsValid()
    }
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it
        bookToEdit.readState = ReadState
        bookToEdit.startedReading = ReadState == .ToRead ? nil : StartedReading
        bookToEdit.finishedReading = ReadState != .Finished ? nil : FinishedReading
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