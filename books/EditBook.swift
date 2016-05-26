//
//  EditBook.swift
//  books
//
//  Created by Andrew Bennet on 25/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Eureka

class EditBook: ChangeBook {
    
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
        setValues(BookPageInputs(title: bookToEdit.title, author: bookToEdit.authorList, pageCount: bookToEdit.pageCount as Int?, publicationDate: bookToEdit.publishedDate, description: bookToEdit.bookDescription))
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
            let splitView = appDelegate.window!.rootViewController as! SplitViewController
            splitView.clearDetailViewIfBookDisplayed(nil)
            splitView.masterNavigationController.popViewControllerAnimated(false)
            
            // Now dismiss *this* modal view
            self.dismissViewControllerAnimated(true, completion: nil)
            })
        self.presentViewController(confirmDeleteAlert, animated: true, completion: nil)
    }
    
    override func onChange() {
        doneButton.enabled = isValid()
    }
    
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        self.view.endEditing(true)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneButtonWasPressed(sender: AnyObject) {
        self.view.endEditing(true)
        
        // Update the book object from the form values
        let formValues = getValues()
        bookToEdit.title = formValues.title!
        bookToEdit.authorList = formValues.author!
        bookToEdit.bookDescription = formValues.description
        bookToEdit.pageCount = formValues.pageCount
        bookToEdit.publishedDate = formValues.publicationDate
        
        // Save the book and dismiss this view.
        appDelegate.booksStore.UpdateSpotlightIndex(bookToEdit)
        appDelegate.booksStore.Save()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}