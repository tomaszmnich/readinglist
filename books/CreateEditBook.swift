//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 28/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka
import UIKit

class CreateEditBook: FormViewController {
    
    var bookToEdit: Book?
    var initialCreateMetadata: BookMetadata?
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title and Author
        let titleAuthorSection = Section()
        titleAuthorSection.append(SegmentedRow<BookReadState>("book-read-state") {
            $0.options = [.Reading, .ToRead, .Finished]
        })
        titleAuthorSection.append(TextRow("title") {
            $0.placeholder = "Title"
        }.onChange{_ in
            self.setStateOfDoneButton()
        })
        titleAuthorSection.append(TextRow("author") {
            $0.placeholder = "Author"
        }.onChange{ _ in
            self.setStateOfDoneButton()
        })
        form.append(titleAuthorSection)
        
        // Page count and Publication date
        let pagePublicationSection = Section()
        pagePublicationSection.append(IntRow("page-count") {
            $0.title = "Number of Pages"
        })
        pagePublicationSection.append(DateRow("publication-date") {
            $0.title = "Publication Date"
        })
        pagePublicationSection.append(TextAreaRow("description"){
            $0.placeholder = "Description"
        }.cellSetup{
            $0.cell.height = {return 200}
        })
        form.append(pagePublicationSection)
        
        // Delete button
        if bookToEdit != nil {
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
        }
    }
    
    private func setValues(bookMetadata: BookMetadata) {
        form.setValues([
            "book-read-state": bookMetadata.readState,
            "title": bookMetadata.title,
            "author": bookMetadata.authorList,
            "page-count": bookMetadata.pageCount,
            "publication-date": bookMetadata.publishedDate,
            "description": bookMetadata.bookDescription])
    }
    
    private func getValues() -> BookMetadata {
        let formValues = form.values()
        let currentValues = BookMetadata()
        currentValues.readState = formValues["book-read-state"] as? BookReadState
        currentValues.title = formValues["title"] as! String
        currentValues.authorList = formValues["author"] as? String
        currentValues.bookDescription = formValues["description"] as? String
        currentValues.pageCount = formValues["page-count"] as? NSNumber
        currentValues.publishedDate = formValues["publication-date"] as? NSDate
        return currentValues
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if bookToEdit != nil {
            setValues(bookToEdit!.RetrieveMetadata())
        }
        else if initialCreateMetadata != nil {
            setValues(initialCreateMetadata!)
        }
        else if let readState = (self.navigationController as? NavWithReadState)?.readState {
            form.setValues(["book-read-state": readState])
        }
        
        setStateOfDoneButton()
    }
    
    private func presentDeleteAlert(){
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
    
    @IBAction func cancelButtonWasPressed(sender: AnyObject) {
        self.view.endEditing(true)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneButtonWasPressed(sender: AnyObject) {
        self.view.endEditing(true)
        
        // Update the book object from the form values
        if let bookToEdit = bookToEdit {
            bookToEdit.UpdateFromMetadata(getValues())
        }
        else {
            appDelegate.booksStore.CreateBook(getValues())
        }
        
        // Save the book and dismiss this view.
        appDelegate.booksStore.Save()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func setStateOfDoneButton() {
        let formValues = form.values()
        
        if (formValues["title"] as? String)?.isEmpty ?? true {
            doneButton.enabled = false
        }
        else if (formValues["author"] as? String)?.isEmpty ?? true {
            doneButton.enabled = false
        }
        else {
            doneButton.enabled = true
        }
    }
}