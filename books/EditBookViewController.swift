//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class EditBookViewController: UIViewController {
    var book: Book!
    var bookListDelegate: BookTableViewControllerDelegate!
    var creatingNewBook = false
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    
    override func viewDidLoad() {
        // Load the values of the fields from the Book
        titleField.text = book.title ?? ""
        authorField.text = book.author ?? ""
    }
    
    @IBAction func donePressed(sender: UIBarButtonItem) {
        // Set the values of the Book from the values of the fields
        book.title = titleField.text
        book.author = authorField.text

        bookListDelegate.editViewDidSave(self)
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelWasPressed(sender: UIBarButtonItem) {
        bookListDelegate.editViewDidCancel(self)
        navigationController?.popViewControllerAnimated(true)
    }
}
