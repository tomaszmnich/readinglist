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
        loadingLabel.textColor = UIColor.gray
        loadingLabel.textAlignment = NSTextAlignment.center
        loadingLabel.text = "Loading..."
        loadingLabel.isHidden = true
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        
        tableView.addSubview(spinner)
        tableView.bringSubview(toFront: spinner)
        tableView.addConstraints([NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerX, relatedBy:NSLayoutRelation.equal, toItem: tableView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0),
                                  NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: tableView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return 0
        }
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BookTableViewCell.self))!
        if let book = results?[indexPath.row] {
            cell.textLabel?.text = book.title
            cell.detailTextLabel?.text = book.authorList
        }
        return cell
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        results?.removeAll(keepingCapacity: false)
        tableView.reloadData()
        loadingLabel.isHidden = false
        spinner.startAnimating()
        searchBar.resignFirstResponder()
        
        OnlineBookClient<GoogleBooksParser>.getBookMetadataOnly(from: GoogleBooksRequest.search(searchBar.text!).url, maxResults: 10, onError: {_ in}) {
            self.spinner.stopAnimating()
            self.loadingLabel.isHidden = true
            self.results = $0
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createBook = segue.destination as? CreateBook {
            let selectedCellPath = tableView.indexPath(for: sender as! UITableViewCell)!
            let selectedBook = results?[selectedCellPath.row]
            createBook.initialBookMetadata = selectedBook
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}
