//
//  AddBookManuallyViewController.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class AddBookManuallyViewController: UIViewController{
    
    lazy var coreDataAccess = appDelegate().coreDataAccess
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    
    
    @IBAction func doneWasPressed(sender: UIBarButtonItem) {
        let book = coreDataAccess.newBook()
        book.title = titleField.text
        
        let author = coreDataAccess.newAuthor()
        author.name = authorField.text
        
        book.authoredBy = NSOrderedSet(array: [author])
        
        coreDataAccess.save()
        self.navigationController!.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func cancelWasPressed(sender: UIBarButtonItem) {
        self.navigationController!.popToRootViewControllerAnimated(true)
    }
}