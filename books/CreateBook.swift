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
            TitleField = initialBookMetadata.title
            AuthorList = initialBookMetadata.authorList
            PageCount = initialBookMetadata.pageCount != nil ? Int(initialBookMetadata.pageCount!) : nil
            PublicationDate = initialBookMetadata.publishedDate
            Description = initialBookMetadata.bookDescription
            if let data = initialBookMetadata.coverImage {
                Image = UIImage(data: data as Data)
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
            
            let finalBookMetadata = initialBookMetadata ?? BookMetadata()
            finalBookMetadata.title = TitleField!
            finalBookMetadata.authorList = AuthorList
            finalBookMetadata.bookDescription = Description
            finalBookMetadata.publishedDate = PublicationDate
            finalBookMetadata.pageCount = PageCount
            finalBookMetadata.coverImage = Image == nil ? nil : UIImagePNGRepresentation(Image!)
            
            createReadState.bookMetadata = finalBookMetadata
        }
    }
}
