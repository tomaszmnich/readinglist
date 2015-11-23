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

class AddBookViewController: UIViewController {

    let moc = appDelegate().coreDataStack.managedObjectContext
    var newBook: Book!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    
    override func viewDidLoad() {
        // Construct a new managed Book object
        newBook = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: moc) as! Book
    }
    
    @IBAction func donePressed(sender: UIBarButtonItem) {
        // Set the values of the Book from the values of the fields
        newBook.title = titleField.text
        newBook.author = authorField.text
        
        // Try to save
        let _ = try? moc.save()

        // Return
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelWasPressed(sender: UIBarButtonItem) {
        // Rollback the creation of this book
        moc.rollback()
        
        // Return
        navigationController?.popViewControllerAnimated(true)
    }
}
