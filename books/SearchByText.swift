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
        spinner.center = self.view.center
        mainTableView.addSubview(spinner)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section != 0 ? 0 : (results?.count ?? 0)
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
        spinner.startAnimating()
        searchBar.resignFirstResponder()
        
        OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(from: GoogleBooksRequest.Search(searchBar.text!).url, maxResults: 10, onError: {_ in}) {
            self.spinner.stopAnimating()
            self.results = $0
            self.mainTableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "createReadStateSegue" else { return }
        
        let selectedCellPath = mainTableView.indexPathForCell(sender as! UITableViewCell)!
        let selectedBook = results?[selectedCellPath.row]
        (segue.destinationViewController as! CreateReadState).bookMetadata = selectedBook
    }
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}