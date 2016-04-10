//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 10/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class EditBookViewController: UITableViewController {
    
    var defaultReadState = BookReadState.Reading
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var authorTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        createBook()
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func titleFieldWasEdited(sender: UITextField) {
        updateDoneEnabledState()
    }
    
    override func viewDidLoad() {
        updateDoneEnabledState()
    }
    
    func updateDoneEnabledState(){
        doneButton.enabled = !titleTextField.text!.isEmpty
    }
    
    func createBook() {
        let bookMetadata = BookMetadata()
        bookMetadata.title = titleTextField.text
        bookMetadata.authorList = authorTextField.text
        bookMetadata.readState = defaultReadState
        appDelegate.booksStore.CreateBook(bookMetadata)
    }
}