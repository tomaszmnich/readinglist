//
//  FilteredFetchedResultsTable.swift
//  books
//
//  Created by Andrew Bennet on 29/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class FilteredFetchedResultsTable: FetchedResultsTable, UISearchResultsUpdating {
    /// The UISearchController to which this UITableViewController is connected.
    var searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        self.definesPresentationContext = true
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.returnKeyType = .done
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Offset by the height of the search bar, so as to hide it on load.
        self.tableView.setContentOffset(CGPoint(x: 0, y: searchController.searchBar.frame.height), animated: false)
        
        super.viewDidLoad()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // We have to update the predicate even if the search text is empty, as the user
        // may have arrived at this state by deleting text from an existing search.
        if let searchText = searchController.searchBar.text {
            updatePredicateAndReloadTable(predicateForSearchText(searchText))
        }
    }
    
    func predicateForSearchText(_ searchText: String) -> NSPredicate {
        // Should be overriden
        return NSPredicate(format: "FALSEPREDICATE")
    }
    
    func isShowingSearchResults() -> Bool {
        return searchController.isActive && searchController.searchBar.text?.isEmpty == false
    }
    
    func dismissSearch() {
        self.searchController.isActive = false
        self.searchController.searchBar.showsCancelButton = false
        self.updateSearchResults(for: self.searchController)
    }
}
