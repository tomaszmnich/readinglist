//
//  CreateBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class CreateBook: BookMetadataForm {
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the ISBN field's section and the delete button
        isbnField.section!.remove(at: isbnField.indexPath!.row)
        updateRow.section!.remove(at: updateRow.indexPath!.row)
        deleteRow.section!.remove(at: deleteRow.indexPath!.row)
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
            
            let finalBookMetadata = BookMetadata()
            populateMetadata(finalBookMetadata)
            createReadState.bookMetadata = finalBookMetadata
        }
    }
}
