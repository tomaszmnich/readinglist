//
//  CreateBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class CreateBook: ChangeBook {
    
    var initialBookMetadata: BookMetadata?
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let initialBookMetadata = initialBookMetadata {
            // Change the title if we are prepopulating the fields
            navigationItem.title = "Add Book"
            
            // Set the field values
            TitleField = initialBookMetadata.title
            AuthorList = initialBookMetadata.authorList
            PageCount = initialBookMetadata.pageCount != nil ? Int(initialBookMetadata.pageCount!) : nil
            PublicationDate = initialBookMetadata.publishedDate
            Description = initialBookMetadata.bookDescription
        }
        
        // Trigger a validation update
        OnChange()
    }
    
    override func OnChange() {
        nextButton.enabled = IsValid()
    }
    
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        Dismiss()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addManuallyNextSegue" {
            let createReadState = segue.destinationViewController as! CreateReadState
            
            let finalBookMetadata = initialBookMetadata ?? BookMetadata()
            finalBookMetadata.title = TitleField!
            finalBookMetadata.authorList = AuthorList
            finalBookMetadata.bookDescription = Description
            finalBookMetadata.publishedDate = PublicationDate
            finalBookMetadata.pageCount = PageCount
            
            createReadState.bookMetadata = finalBookMetadata
        }
        
    }
}