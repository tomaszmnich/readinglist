//
//  SearchByText.swift
//  books
//
//  Created by Andrew Bennet on 25/08/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class SearchByText: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var mainTableView: UITableView!
    var results: [BookMetadata]?
    var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.tableFooterView = UIView()
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
        spinner = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40))
        spinner.activityIndicatorViewStyle = .Gray
        spinner.hidesWhenStopped = true
        spinner.center = self.mainTableView.center
        mainTableView.addSubview(spinner)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != 0 {
            return 0
        }
        return results?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(String(BookTableViewCell)) as! BookTableViewCell

        if let book = results?[indexPath.row] {
            cell.configureFrom(book)
        }
        return cell
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        results?.removeAll(keepCapacity: false)
        mainTableView.reloadData()
        spinner.startAnimating()
        searchBar.resignFirstResponder()
        
        OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(from: GoogleBooksRequest.Search(searchBar.text!).url, maxResults: 10, onError: {_ in}) {
            self.spinner.stopAnimating()
            self.results = $0
            self.mainTableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let createBook = segue.destinationViewController as? CreateBook {
            let selectedCellPath = mainTableView.indexPathForCell(sender as! UITableViewCell)!
            let selectedBook = results?[selectedCellPath.row]
            createBook.initialBookMetadata = selectedBook
        }
    }
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}