//
//  SettingsViewController.swift
//  books
//
//  Created by Andrew Bennet on 01/12/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {
    
    var booksProcessed = 0
    
    let isbns = ["9780099529125", "9780241950432", "9780099800200", "9780006546061", "9781442369054", "9780007532766", "9780718197384", "9780099889809", "9780241197790"]
    
    func addBook(parsedResult: BookMetadata?){
        dispatch_async(dispatch_get_main_queue()) {
        self.booksProcessed++
        if parsedResult != nil{
            appDelegate.booksStore.CreateBook(parsedResult!)
        }
        
        if self.booksProcessed == self.isbns.count{
            appDelegate.booksStore.Save()
            let alert = UIAlertController(title: "Complete", message: "\(self.booksProcessed) Books Added", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func populateDataIsPressed(sender: UIButton) {
        booksProcessed = 0
        for isbn in isbns{
            GoogleBooksApiClient.SearchByIsbn(isbn, callback: addBook)
        }

    }
    
}