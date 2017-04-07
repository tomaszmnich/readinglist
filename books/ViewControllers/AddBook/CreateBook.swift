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
        
        if let initialBookMetadata = initialBookMetadata {
            // Change the title if we are prepopulating the fields
            navigationItem.title = "Add Book"
            
            // Set the field values
            titleField = initialBookMetadata.title
            authorList = initialBookMetadata.authors
            descriptionField = initialBookMetadata.bookDescription
            if let data = initialBookMetadata.coverImage {
                image = UIImage(data: data)
            }
        }
        
        // Trigger a validation update
        onChange()
    }
    
    override func onChange() {
        nextButton.isEnabled = isValid
    }
    
    @IBAction func cancelButtonWasPressed(_ sender: AnyObject) {
        dismiss()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createReadState = segue.destination as? CreateReadState {
            
            let finalBookMetadata = initialBookMetadata ?? BookMetadata(title: titleField!, authors: authorList!)
            finalBookMetadata.bookDescription = descriptionField
            finalBookMetadata.coverImage = image == nil ? nil : UIImageJPEGRepresentation(image!, 0.7)
            
            createReadState.bookMetadata = finalBookMetadata
        }
    }
}
