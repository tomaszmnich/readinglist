//
//  EditBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Eureka

class EditBook: BookMetadataForm {
    
    var bookToEdit: Book!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a Delete button
        let deleteSection = Section()
        deleteSection.append(ButtonRow("delete"){
            $0.title = "Delete Book"
            }.cellSetup{cell, row in
                cell.tintColor = UIColor.red
            }
            .onCellSelection{ _ in
                self.presentDeleteAlert()
            })
        form.append(deleteSection)
        
        // Initialise the form with the book values
        TitleField = bookToEdit.title
        AuthorList = bookToEdit.authorList
        PageCount = bookToEdit.pageCount != nil ? Int(bookToEdit.pageCount!) : nil
        PublicationDate = bookToEdit.publishedDate
        Description = bookToEdit.bookDescription
        Image = UIImage(optionalData: bookToEdit.coverImage)
    }
    
    func presentDeleteAlert(){
        // We are going to show an action sheet
        let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Bring up the action sheet)
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            
            // Dismiss this modal view and then delete the book
            self.dismiss(animated: true) {
                appDelegate.booksStore.delete(self.bookToEdit)
            }
        })
        self.present(confirmDeleteAlert, animated: true, completion: nil)
    }
    
    override func onChange() {
        doneButton.isEnabled = isValid
    }
    
    @IBAction func cancelButtonWasPressed(_ sender: AnyObject) {
        dismiss()
    }
    
    @IBAction func doneButtonWasPressed(_ sender: AnyObject) {
        // Check the title field is not nil
        guard let TitleField = TitleField else { return }
        
        // Load the book metadata into an object from the form values
        let newMetadata = BookMetadata()
        newMetadata.title = TitleField
        newMetadata.authorList = AuthorList
        newMetadata.bookDescription = Description
        newMetadata.pageCount = PageCount
        newMetadata.publishedDate = PublicationDate
        newMetadata.coverImage = Image == nil ? nil : UIImageJPEGRepresentation(Image!, 0.7)
        
        // Update and save the book
        bookToEdit.populate(from: newMetadata)
        appDelegate.booksStore.updateSpotlightIndex(for: bookToEdit)
        appDelegate.booksStore.save()

        dismiss()
    }
}
