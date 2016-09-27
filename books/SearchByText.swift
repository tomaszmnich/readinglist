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
    
    fileprivate var spinner = UIActivityIndicatorView()
    fileprivate var loadingLabel = UILabel()
    fileprivate var loadingView = UIView()
    
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
        CGRect(x: x, y: y, width: width, height: height)

        loadingLabel.textColor = UIColor.gray
        loadingLabel.textAlignment = NSTextAlignment.center
        loadingLabel.text = "Loading..."
        loadingLabel.isHidden = true
        //loadingLabel.frame = CGRectMake(0, 0, 140, 30)
        
        spinner.activityIndicatorViewStyle = .gray
        //spinner.frame = CGRectMake(0, 0, 30, 30)
        spinner.hidesWhenStopped = true
        
        loadingView.addSubview(spinner)
        loadingView.addSubview(loadingLabel)
        
        tableView.addSubview(loadingView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != 0 {
            return 0
        }
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BookTableViewCell.self)) as! BookTableViewCell

        if let book = results?[(indexPath as NSIndexPath).row] {
            cell.configureFrom(book)
        }
        return cell
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        results?.removeAll(keepingCapacity: false)
        tableView.reloadData()
        loadingLabel.isHidden = false
        spinner.startAnimating()
        searchBar.resignFirstResponder()
        
        OnlineBookClient<GoogleBooksParser>.TryGetBookMetadata(from: GoogleBooksRequest.search(searchBar.text!).url, maxResults: 10, onError: {_ in}) {
            self.spinner.stopAnimating()
            self.loadingLabel.isHidden = true
            self.results = $0
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createBook = segue.destination as? CreateBook {
            let selectedCellPath = tableView.indexPath(for: sender as! UITableViewCell)!
            let selectedBook = results?[(selectedCellPath as NSIndexPath).row]
            createBook.initialBookMetadata = selectedBook
        }
    }
    
    @IBAction func cancelWasPressed(_ sender: AnyObject) {
        searchBar.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}
