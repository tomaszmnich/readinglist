//
//  CreateBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class CreateBook: BookMetadataForm {
    
    var initialBookMetadata: BookMetadata?
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the ISBN field's section and the delete button
        isbnField.section!.remove(at: isbnField.indexPath!.row)
        deleteRow.section!.hidden = true
        deleteRow.section!.evaluateHidden()
        
        if let initialBookMetadata = initialBookMetadata {
            // Change the title if we are prepopulating the fields
            navigationItem.title = "Add Book"
            
            // Set the field values
            titleField.value = initialBookMetadata.title
            authors = initialBookMetadata.authors
            descriptionField.value = initialBookMetadata.bookDescription
            pageCount.value = initialBookMetadata.pageCount
            publicationDate.value = initialBookMetadata.publicationDate
            if let data = initialBookMetadata.coverImage {
                image.value = UIImage(data: data)
            }
        }
    }
    
    override func formValidated(isValid: Bool) {
        nextButton.isEnabled = isValid
    }
    
    @IBAction func cancelButtonWasPressed(_ sender: AnyObject) {
        dismiss()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let createReadState = segue.destination as? CreateReadState {
            UserEngagement.logEvent(.addManualBook)
            
            let finalBookMetadata = initialBookMetadata ?? BookMetadata()
            populateMetadata(finalBookMetadata)
            createReadState.bookMetadata = finalBookMetadata
        }
    }
}
