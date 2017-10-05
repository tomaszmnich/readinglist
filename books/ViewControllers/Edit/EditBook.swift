//
//  EditBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import SVProgressHUD
import Eureka

class EditBook: BookMetadataForm {
    var bookToEdit: Book!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        authors = bookToEdit.authorsArray.map{($0.firstNames, $0.lastName)}
        subjects = bookToEdit.subjects.array.map{($0 as! Subject).name}
        
        super.viewDidLoad()
        
        // Disable the ISBN field (disallow editing of the ISBN), and wire up the delete button
        isbnField.disabled = true
        isbnField.evaluateDisabled()
        
        if bookToEdit.googleBooksId == nil {
            updateRow.section!.remove(at: updateRow.indexPath!.row)
        }
        else {
            updateRow.onCellSelection { [unowned self] _,_ in
                self.presentUpdateAltert()
            }
        }
        
        deleteRow.onCellSelection{ [unowned self] _,_ in
            self.presentDeleteAlert()
        }
        
        // Initialise the form with the book values
        isbnField.value = bookToEdit.isbn13
        if bookToEdit.isbn13 == nil {
            isbnField.section!.remove(at: isbnField.indexPath!.row)
        }
        titleField.value = bookToEdit.title
        pageCount.value = bookToEdit.pageCount == nil ? nil : Int(truncating: bookToEdit.pageCount!)
        publicationDate.value = bookToEdit.publicationDate
        descriptionField.value = bookToEdit.bookDescription
        image.value = UIImage(optionalData: bookToEdit.coverImage)
    }
    
    func presentUpdateAltert() {
        SVProgressHUD.show(withStatus: "Downloading...")
        GoogleBooks.fetch(googleBooksId: bookToEdit.googleBooksId!) { [unowned self] fetchResultPage in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                guard fetchResultPage.result.isSuccess else {
                    SVProgressHUD.showError(withStatus: "Could not update book details")
                    return
                }
                appDelegate.booksStore.update(book: self.bookToEdit, withMetadata: fetchResultPage.result.value!.toBookMetadata())
                self.dismiss {
                    SVProgressHUD.showInfo(withStatus: "Book updated")
                }
            }
        }
    }
    
    func presentDeleteAlert(){
        // We are going to show an action sheet
        let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Bring up the action sheet)
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) {[unowned self] _ in
            
            // Dismiss this modal view and then delete the book
            self.dismiss(animated: true) {
                appDelegate.booksStore.deleteBook(self.bookToEdit)
                UserEngagement.logEvent(.deleteBook)
            }
        })
        self.present(confirmDeleteAlert, animated: true, completion: nil)
    }
    
    override func formValidated(isValid: Bool) {
        doneButton.isEnabled = isValid
    }
    
    @IBAction func cancelButtonWasPressed(_ sender: AnyObject) {
        // Check for changes
        let newMetadata = BookMetadata(book: bookToEdit)
        if populateMetadata(newMetadata) {
            // Confirm exit dialog
            let confirmExit = UIAlertController(title: "Unsaved changes", message: "Are you sure you want to discard your unsaved changes?", preferredStyle: .actionSheet)
            confirmExit.addAction(UIAlertAction(title: "Discard", style: .destructive){ [unowned self] _ in
                self.dismiss()
            })
            confirmExit.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(confirmExit, animated: true, completion: nil)
        }
        else {
            dismiss()
        }
    }
    
    @IBAction func doneButtonWasPressed(_ sender: AnyObject) {
        // Check the title field is not nil
        guard titleField.value != nil && authors.count >= 1 else { return }
        
        // Load the book metadata into an object from the form values
        let newMetadata = BookMetadata(book: bookToEdit)
        populateMetadata(newMetadata)
        
        // Update the book
        appDelegate.booksStore.update(book: bookToEdit, withMetadata: newMetadata)
        dismiss {
            UserEngagement.logEvent(.editBook)
            UserEngagement.onReviewTrigger()
        }
    }
}
