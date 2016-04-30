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

class EditBookViewController: FormViewController {
    
    var book: Book!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bookDetailsSection = Section()
        bookDetailsSection.append(SegmentedRow<BookReadState>("book-read-state") {
            $0.options = [.ToRead, .Reading, .Finished]
            $0.value = book.readState
        })
        bookDetailsSection.append(TextRow("title") {
            $0.placeholder = "Title"
            $0.value = book.title
        }.onChange{_ in
            self.setStateOfDoneButton()
        })
        bookDetailsSection.append(TextRow("author") {
            $0.placeholder = "Author"
            $0.value = book.authorList
        }.onChange{ _ in
            self.setStateOfDoneButton()
        })
        bookDetailsSection.append(TextAreaRow("description") {
            $0.placeholder = "Description"
            $0.value = book.bookDescription
        })
        form.append(bookDetailsSection)
        
        let deleteSection = Section()
        deleteSection.append(ButtonRow("delete"){
            $0.title = "Delete Book"
        }.onCellSelection{ _ in
            // We are going to show an action sheet
            let confirmDeleteAlert = UIAlertController(title: "Delete?", message: nil, preferredStyle: .ActionSheet)
            
            // Bring up the action sheet)
            confirmDeleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            confirmDeleteAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive) { _ in
                appDelegate.booksStore.DeleteBookAndDeindex(self.book)
                self.navigationController?.popViewControllerAnimated(true)
                // TODO: Dismiss the *other* navigation controller.
            })
            self.presentViewController(confirmDeleteAlert, animated: true, completion: nil)
        })
        form.append(deleteSection)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: The setting of the values should be done here, not in viewDidLoad().
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
        else{
            doneButton.enabled = true
        }
    }
}