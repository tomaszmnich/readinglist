//
//  EditBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class EditBook: BookMetadataForm {
    
    var bookToEdit: Book!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the ISBN field (disallow editing of the ISBN), and wire up the delete button
        isbnField.disabled = true
        isbnField.evaluateDisabled()
        deleteRow.onCellSelection{ [unowned self] _ in
            self.presentDeleteAlert()
        }
        
        // Initialise the form with the book values
        isbnField.value = bookToEdit.isbn13
        if bookToEdit.isbn13 == nil {
            isbnField.section!.hidden = true
            isbnField.section!.evaluateHidden()
        }
        titleField.value = bookToEdit.title
        authorList.value = bookToEdit.authorList
        pageCount.value = bookToEdit.pageCount == nil ? nil : Int(bookToEdit.pageCount!)
        publicationDate.value = bookToEdit.publicationDate
        descriptionField.value = bookToEdit.bookDescription
        image.value = UIImage(optionalData: bookToEdit.coverImage)
    }
    
    func presentDeleteAlert(){
        // We are going to show an action sheet
        let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Bring up the action sheet)
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) {[unowned self] _ in
            
            // Dismiss this modal view and then delete the book
            self.dismiss(animated: true) {
                appDelegate.booksStore.delete(self.bookToEdit)
            }
        })
        self.present(confirmDeleteAlert, animated: true, completion: nil)
    }
    
    override func formValidated(isValid: Bool) {
        doneButton.isEnabled = isValid
    }
    
    @IBAction func cancelButtonWasPressed(_ sender: AnyObject) {
        dismiss()
    }
    
    @IBAction func doneButtonWasPressed(_ sender: AnyObject) {
        // Check the title field is not nil
        guard let titleFieldValue = titleField.value, let authorListValue = authorList.value else { return }
        
        // Load the book metadata into an object from the form values
        let newMetadata = BookMetadata()
        newMetadata.title = titleFieldValue
        newMetadata.authors = authorListValue
        newMetadata.pageCount = pageCount.value
        newMetadata.publicationDate = publicationDate.value
        newMetadata.bookDescription = descriptionField.value
        newMetadata.coverImage = image.value == nil ? nil : UIImageJPEGRepresentation(image.value!, 0.7)
        
        // Update the book
        appDelegate.booksStore.update(book: bookToEdit, withMetadata: newMetadata)
        dismiss()
    }
}
