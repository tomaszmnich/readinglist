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
        ReadState = bookMetadata.readState
        StartedReading = bookMetadata.startedReading
        FinishedReading = bookMetadata.finishedReading
    }
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it
        bookMetadata.readState = ReadState
        bookMetadata.startedReading = ReadState == .ToRead ? nil : StartedReading
        bookMetadata.finishedReading = ReadState != .Finished ? nil : FinishedReading
        appDelegate.booksStore.CreateBook(bookMetadata)
        appDelegate.booksStore.Save()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func OnChange() {
        doneButton.enabled = IsValid()
    }
}