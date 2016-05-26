//
//  CreateBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class CreateBook: ChangeBook {
    
    var bookMetadata: BookMetadata!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the form with the book values
        setValues(BookPageInputs(title: bookMetadata.title, author: bookMetadata.authorList, pageCount: bookMetadata.pageCount as Int?, publicationDate: bookMetadata.publishedDate, description: bookMetadata.bookDescription))
        
        // Trigger a validation update
        onChange()
    }
    
    override func onChange() {
        doneButton.enabled = isValid()
    }
    
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        self.view.endEditing(true)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addManuallyNextSegue" {
            let createReadState = segue.destinationViewController as! CreateReadState
            
            let formValues = getValues()
            bookMetadata.title = formValues.title
            bookMetadata.authorList = formValues.author
            bookMetadata.bookDescription = formValues.description
            bookMetadata.publishedDate = formValues.publicationDate
            bookMetadata.pageCount = formValues.pageCount
            createReadState.bookMetadata = bookMetadata
        }
        
    }
}