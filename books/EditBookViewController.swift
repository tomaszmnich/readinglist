//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord
import UIKit

class EditBookViewController: UIViewController {
    var book = Book(title: "", author: "")
    var bookListDelegate: BookTableViewControllerDelegate!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    
    override func viewDidLoad() {
        print("Edit book view loaded")
        titleField.text = book.title
        authorField.text = book.author
    }
    
    @IBAction func donePressed(sender: UIBarButtonItem) {
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
