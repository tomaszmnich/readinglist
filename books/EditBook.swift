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
                cell.tintColor = UIColor.redColor()
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
    }
    
    func presentDeleteAlert(){
        // We are going to show an action sheet
        let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // Bring up the action sheet)
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive) { _ in
            appDelegate.booksStore.DeleteBookAndDeindex(self.bookToEdit!)
            
            // If the detail view is present, clear it.
            // Otherwise, pop it.
            appDelegate.splitViewController.bookDetailsControllerIfSplit?.ClearUI()
            appDelegate.splitViewController.masterNavigationController.popToRootViewControllerAnimated(false)
            
            // Now dismiss *this* modal view
            self.dismissViewControllerAnimated(true, completion: nil)
            })
        self.presentViewController(confirmDeleteAlert, animated: true, completion: nil)
    }
    
    override func OnChange() {
        doneButton.enabled = IsValid()
    }
    
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        Dismiss()
    }
    
    @IBAction func doneButtonWasPressed(sender: AnyObject) {
        // Check the title field is not nil
        guard let TitleField = TitleField else { return }
        
        // Update the book object from the form values
        self.view.endEditing(true)

        bookToEdit.title = TitleField
        bookToEdit.authorList = AuthorList
        bookToEdit.bookDescription = Description
        bookToEdit.pageCount = PageCount
        bookToEdit.publishedDate = PublicationDate
        
        // Save the book
        appDelegate.booksStore.UpdateSpotlightIndex(bookToEdit)
        appDelegate.booksStore.Save()

        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}