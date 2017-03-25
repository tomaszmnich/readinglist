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
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        navigationItem.title = bookMetadata.title
        
        super.viewDidLoad()
        
        // Set the read state on the form; add some default form values for the dates
        readState = (self.navigationController as! NavWithReadState).readState
        startedReading = Date.startOfToday()
        finishedReading = Date.startOfToday()
    }
    
    @IBAction func doneWasPressed(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it.
        // Ignore the dates which are not relevant.
        let bookReadingInformation = BookReadingInformation(readState: readState, startedWhen: startedReading, finishedWhen: finishedReading)
        appDelegate.booksStore.create(from: bookMetadata, readingInformation: bookReadingInformation)
        
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func onChange() {
        doneButton.isEnabled = isValid
    }
}
