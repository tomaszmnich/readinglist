//
//  SearchResultsViewController.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import SwiftyJSON

class SearchResultsViewController: UIViewController{
 
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    /// This must be populated by any controller segueing to this one
    var isbn13: String!
    var bookReadState: BookReadState!
    var book: Book!
    
    // We will likely need data access
    lazy var booksStore = appDelegate.booksStore
    
    override func viewDidLoad() {
        spinner.startAnimating()
        
        // We've found an ISBN-13. Let's search for it online and if we
        // find anything useful use it to build a Book object.
        HttpClient.GetJson(GoogleBooksRequest.Search(isbn13).url, callback: ProcessSearchResult)
    }
        
    /// Responds to a search result completion
    func ProcessSearchResult(result: JSON?) {
        if(result != nil){
            
            // We have a result, so make a Book and populate it
            book = booksStore.CreateBook()
            book.readState = bookReadState
            GoogleBooksParser.parseJsonResponseIntoBook(book, jResponse: result!)
            
            // If there was an image URL in the result, request that too
            if book.coverUrl != nil {
                HttpClient.GetData(book.coverUrl!, callback: SupplementBookWithCoverImageAndExit)
            }
            else{
                StopSpinnerAndExit()
            }
        }
        else{
            PresentNoResultsAlert()
        }
    }
    
    /**
     Adds the provided data as the coverImage to the book on this controller, saves the book,
     indexes it in spotlight, and calls the exit method.
    */
    func SupplementBookWithCoverImageAndExit(data: NSData?){
        if data == nil {
            print("No data received.")
        }
        book.coverImage = data
    
        // Save the book and index it.
        booksStore.Save()
        booksStore.IndexBookInSpotlight(book)
    
        // Exit
        StopSpinnerAndExit()
    }
    
    /// Stops the spinner and dismisses this view controller.
    func StopSpinnerAndExit(){
        spinner.stopAnimating()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Presents a popup alerting the use to the fact that there were no results.
    func PresentNoResultsAlert() {
        let alert = UIAlertController(title: "No Results", message: "No matching book found online.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
            alertAction in
            self.StopSpinnerAndExit();
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}