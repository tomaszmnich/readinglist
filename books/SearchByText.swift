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
    
    @IBOutlet weak var tableView: UITableView!
    
    var results: [BookMetadata]?
    
    private var spinner = UIActivityIndicatorView()
    private var loadingLabel = UILabel()
    private var loadingView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the table. This controller is not a UITableViewController so that we can have more
        // controller over the search bar.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
        
        // Setup loading screen
        let width: CGFloat = 120
        let height: CGFloat = 30
        let x = (self.tableView.frame.width - width)/2
        let y = (self.tableView.frame.height - height)/2 - self.navigationController!.navigationBar.frame.height
        loadingView.center = self.tableView.center
        CGRectMake(x, y, width, height)

        loadingLabel.textColor = UIColor.grayColor()
        loadingLabel.textAlignment = NSTextAlignment.Center
        loadingLabel.text = "Loading..."
        loadingLabel.hidden = true
        //loadingLabel.frame = CGRectMake(0, 0, 140, 30)
        
        spinner.activityIndicatorViewStyle = .Gray
        //spinner.frame = CGRectMake(0, 0, 30, 30)
        spinner.hidesWhenStopped = true
        
        loadingView.addSubview(spinner)
        loadingView.addSubview(loadingLabel)
        
        tableView.addSubview(loadingView)
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
        tableView.reloadData()
        loadingLabel.hidden = false
        spinner.startAnimating()
        searchBar.resignFirstResponder()
        
        OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(from: GoogleBooksRequest.Search(searchBar.text!).url, maxResults: 10, onError: {_ in}) {
            self.spinner.stopAnimating()
            self.loadingLabel.hidden = true
            self.results = $0
            self.tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let createBook = segue.destinationViewController as? CreateBook {
            let selectedCellPath = tableView.indexPathForCell(sender as! UITableViewCell)!
            let selectedBook = results?[selectedCellPath.row]
            createBook.initialBookMetadata = selectedBook
        }
    }
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}