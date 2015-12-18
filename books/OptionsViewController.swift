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
    
    let booksToAdd: [(isbn: String, readState: BookReadState)] =
        [("9780099529125", .Finished),
         ("9780241950432", .ToRead),
         ("9780099800200", .Finished),
         ("9780006546061", .Finished),
         ("9781442369054", .ToRead),
         ("9780007532766", .ToRead),
         ("9780718197384", .Finished),
         ("9780099889809", .ToRead),
         ("9780241197790", .Reading)]
    
    func makeAddBookFunc(readState: BookReadState) -> (BookMetadata?) -> Void{
        func addBook(parsedResult: BookMetadata?){
        dispatch_async(dispatch_get_main_queue()) {
            self.booksProcessed++
            if parsedResult != nil{
                parsedResult!.readState = readState
                appDelegate.booksStore.CreateBook(parsedResult!)
            }
            
            self.showMessageIfAllAdded()
            }
        }
        
        return addBook
    }
    
    func showMessageIfAllAdded() {
        if self.booksProcessed == self.booksToAdd.count{
            appDelegate.booksStore.Save()
            let alert = UIAlertController(title: "Complete", message: "\(self.booksProcessed) Books Added", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func populateDataIsPressed(sender: UIButton) {
        booksProcessed = 0
        for bookToAdd in booksToAdd{
            GoogleBooksApiClient.SearchByIsbn(bookToAdd.isbn, callback: makeAddBookFunc(bookToAdd.readState))
        }

    }
    
}