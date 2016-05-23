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

class EditBook: FormViewController {
    
    var book: Book!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title and Author
        let titleAuthorSection = Section("Book Information")
        titleAuthorSection.append(SegmentedRow<BookReadState>("book-read-state") {
            $0.options = [.Reading, .ToRead, .Finished]
            $0.value = book.readState
        })
        titleAuthorSection.append(TextRow("title") {
            $0.placeholder = "Title"
            $0.value = book.title
        }.onChange{_ in
            self.setStateOfDoneButton()
        })
        titleAuthorSection.append(TextRow("author") {
            $0.placeholder = "Author"
            $0.value = book.authorList
        }.onChange{ _ in
            self.setStateOfDoneButton()
        })
        form.append(titleAuthorSection)
        
        // Page count and Publication date
        let pagePublicationSection = Section("Book Details")
        pagePublicationSection.append(IntRow("page-count") {
            $0.title = "Pages"
            $0.value = book.pageCount as Int?
        })
        pagePublicationSection.append(DateRow("publication-date") {
            $0.title = "Published"
            $0.value = book.publishedDate
        })
        form.append(pagePublicationSection)
        
        // Description
        let descriptionSection = Section("Description")
        descriptionSection.append(TextAreaRow("description") {
            $0.placeholder = "Description"
            $0.value = book.bookDescription
        })
        form.append(descriptionSection)
        
        // Delete button
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: The setting of the values should be done here, not in viewDidLoad().
    }
    
    func presentDeleteAlert(){
        // We are going to show an action sheet
        let confirmDeleteAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // Bring up the action sheet)
        confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive) { _ in
            appDelegate.booksStore.DeleteBookAndDeindex(self.book)
            
            // Pop the detail view, so that the table view is ready for us
            let splitView = self.presentingViewController as! SplitViewController
            splitView.clearDetailView()
            splitView.masterNavigationController.popViewControllerAnimated(false)
            
            // Now dismiss *this* modal view, showing the table view.
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
        let formValues = form.values()
        
        // Update the book object from the form values
        book.readState = formValues["book-read-state"] as! BookReadState
        book.title = formValues["title"] as! String
        book.authorList = formValues["author"] as? String
        book.bookDescription = formValues["description"] as? String
        book.pageCount = formValues["page-count"] as? NSNumber
        book.publishedDate = formValues["publication-date"] as? NSDate
        
        // Save the book and dismiss this view.
        appDelegate.booksStore.Save()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setStateOfDoneButton() {
        let formValues = form.values()
        
        if (formValues["title"] as? String)?.isEmpty ?? true{
            doneButton.enabled = false
        }
        else if (formValues["author"] as? String)?.isEmpty ?? true{
            doneButton.enabled = false
        }
        else {
            doneButton.enabled = true
        }
    }
}