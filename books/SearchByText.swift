//
//  SearchByText.swift
//  books
//
//  Created by Andrew Bennet on 25/08/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class SearchByText: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidDisappear(animated: Bool) {
        spinner.stopAnimating()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        spinner.startAnimating()

        //OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(GoogleBooksRequest.Search(searchBar.text!).url, completionHandler: self.searchResultsReceived)
        searchResultsReceived(BookMetadata(), error: nil)
    }
    
    func searchResultsReceived(results: BookMetadata?, error: NSError?) {
        performSegueWithIdentifier("showTextSearchResultsSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "showTextSearchResultsSegue"){
            (segue.destinationViewController as! SearchResults).searchResults = [BookMetadata]()
        }
    }
    
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}