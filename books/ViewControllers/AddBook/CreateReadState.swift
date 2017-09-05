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
        super.viewDidLoad()
        
        navigationItem.title = bookMetadata.title
        
        // Set the read state on the form; add some default form values for the dates
        readState.value = (self.navigationController as! NavWithReadState).readState
    }
    
    @IBAction func doneWasPressed(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        // Update the book metadata object and create a book from it.
        // Ignore the dates which are not relevant.
        let bookReadingInformation = BookReadingInformation(readState: readState.value!, startedWhen: startedReading.value, finishedWhen: finishedReading.value, currentPage: currentPage.value)
        let createdBook = appDelegate.booksStore.create(from: bookMetadata, readingInformation: bookReadingInformation, readingNotes: notes.value)
        
        // Select the relevant tab and scroll to the position of the new book
        appDelegate.tabBarController.selectTab(readState.value! == .finished ? .finished : .toRead)
        if let selectedTable = appDelegate.tabBarController.selectedBookTable,
            let newBookIndexPath = selectedTable.resultsController.indexPath(forObject: createdBook) {
            selectedTable.tableView.scrollToRow(at: newBookIndexPath, at: .none, animated: true)
        }

        self.navigationController?.dismiss(animated: true) {
            UserEngagement.onReviewTrigger()
        }
    }
    
    override func formValidated(isValid: Bool) {
        doneButton.isEnabled = isValid
    }
}
