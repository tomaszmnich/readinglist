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
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        spinner.startAnimating()
        OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(GoogleBooksRequest.Search(searchBar.text!).url, completionHandler: self.searchResultsReceived)
    }
    
    func searchResultsReceived(results: BookMetadata?, error: NSError?){
        
    }
    
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}