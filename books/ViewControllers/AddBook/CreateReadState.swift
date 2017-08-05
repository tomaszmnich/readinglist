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
        readState.value = (self.navigationController as! NavWithReadState).readState
    }
    
    @IBAction func doneWasPressed(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it.
        // Ignore the dates which are not relevant.
        let bookReadingInformation = BookReadingInformation(readState: readState.value!, startedWhen: startedReading.value, finishedWhen: finishedReading.value, currentPage: currentPage.value)
        appDelegate.booksStore.create(from: bookMetadata, readingInformation: bookReadingInformation, readingNotes: notes.value)
        
        appDelegate.splitViewController.tabbedViewController.setSelectedTab(to: readState.value! == .finished ? .finished : .toRead)
        self.navigationController?.dismiss(animated: true) {
            UserEngagement.onReviewTrigger()
        }
    }
    
    override func formValidated(isValid: Bool) {
        doneButton.isEnabled = isValid
    }
}
