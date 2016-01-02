//
//  SearchResultsViewController.swift
//  books
//
//  Created by Andrew Bennet on 29/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController{
 
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    /// This must be populated by any controller segueing to this one
    var isbn13: String!
    var bookReadState: BookReadState!
    
    // We will likely need data access
    lazy var booksStore = appDelegate.booksStore
    
    override func viewDidLoad() {
        spinner.startAnimating()
        
        // We've found an ISBN-13. Let's search for it online and if we
        // find anything useful use it to build a Book object.
        GoogleBooksApiClient.SearchByIsbn(isbn13, callback: ProcessSearchResult)
    }
        
    /// Responds to a search result completion
    func ProcessSearchResult(result: BookMetadata?){
        if(result != nil){
            // just in case...
            result!.readState = bookReadState
            
            // Construct a new book
            let newBook = booksStore.CreateBook(result!)
            
            // Save the book!
            self.booksStore.Save()
            
            // Index the book in Spotlight
            booksStore.IndexBookInSpotlight(newBook)
        }
        
        // TODO: Do something other than just going back at this point
        spinner.stopAnimating()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}