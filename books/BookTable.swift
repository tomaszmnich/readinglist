//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CoreData
import CoreSpotlight

class BookTable: AutoUpdatingTableViewController {
    
    var resultsController: NSFetchedResultsController<Book>!
    var resultsFilterer: FetchedResultsFilterer<Book, BookPredicateBuilder>!
    var readStates: [BookReadState]!
    
    override func viewDidLoad() {
        let readStatePredicate = NSPredicate.Or(readStates.map{BookPredicate.readState(equalTo: $0)})
        
        // Set up the results controller
        resultsController = appDelegate.booksStore.fetchedResultsController(readStatePredicate, initialSortDescriptors: [BookPredicate.readStateSort, NSSortDescriptor(key: "sort", ascending: true), NSSortDescriptor(key: "startedReading", ascending: true), NSSortDescriptor(key: "finishedReading", ascending: true)])
    
        // Assign the table updator, which will deal with changes to the data
        tableUpdater = TableUpdater<Book, BookTableViewCell>(table: tableView, controller: resultsController)
        
        /// The UISearchController to which this UITableViewController will be connected.
        let searchController = UISearchController(searchResultsController: nil)
        let predicateBuilder = BookPredicateBuilder(readStatePredicate: readStatePredicate)
        resultsFilterer = FetchedResultsFilterer(uiSearchController: searchController, tableView: self.tableView, fetchedResultsController: resultsController, predicateBuilder: predicateBuilder)
        
        // Search Controller UI decisions
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        searchController.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar

        // We will manage the clearing of selections ourselves.
        clearsSelectionOnViewWillAppear = false
        
        // Setting the table footer removes the cell separators.
        tableView.tableFooterView = UIView()
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self

        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Deselect selected rows, so they don't stay highlighted
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
        
        super.viewDidAppear(animated)
    }    

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Turn the section name into a BookReadState and use its description property
        let sectionAsInt = Int32(self.resultsController.sections![section].name)!
        return BookReadState(rawValue: sectionAsInt)!.description
    }
    
    func triggerBookSelection(_ book: Book){
        // There must be a row corresponding to this book
        guard let indexPathOfSelectedBook = self.resultsController.indexPath(forObject: book) else { return }
            
        // Dismiss the search if there is one
        resultsFilterer.dismissSearch()
        
        // Scroll to and select the row
        self.tableView.scrollToRow(at: indexPathOfSelectedBook, at: .none, animated: false)
        self.tableView.selectRow(at: indexPathOfSelectedBook, animated: false, scrollPosition: .none)
        
        // If there is a detail view presented, pop back to the tabbed page.
        if appDelegate.splitViewController.detailIsPresented {
            let _ = appDelegate.splitViewController.rootDetailViewController?.navigationController?.popToViewController(appDelegate.splitViewController.tabbedViewController, animated: false)
        }
        
        // Segue to the details view, with the cell corresponding to the book as the sender
        self.performSegue(withIdentifier: "showDetail", sender: tableView.cellForRow(at: indexPathOfSelectedBook))
        
        // Get rid of any modal controllers (e.g. edit views, etc)
        self.presentedViewController?.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailsViewController = (segue.destination as? UINavigationController)?.topViewController as? BookDetails,
            let cell = sender as? UITableViewCell,
            let selectedIndex = self.tableView.indexPath(for: cell) {
         
            detailsViewController.book = self.resultsController.object(at: selectedIndex)
        }
    }
}

/// Editing logic.
extension BookTable {

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let selectedBook = self.resultsController.object(at: indexPath)
        
        // Helper function to create actions which modify the read states of books
        func updateReadStateAction(title: String, newReadState: BookReadState, actionColour: UIColor) -> UITableViewRowAction {
            let action = UITableViewRowAction(style: .normal, title: title) { _, _ in
                selectedBook.readState = newReadState
                selectedBook.setDate(Date(), forState: newReadState)
                selectedBook.sort = nil
                appDelegate.booksStore.updateSpotlightIndex(for: selectedBook)
                appDelegate.booksStore.save()
                self.tableView.setEditing(false, animated: true)
            }
            action.backgroundColor = actionColour
            return action
        }
        
        var editActions = [UITableViewRowAction]()
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { _, _ in
            appDelegate.booksStore.delete(selectedBook)
            appDelegate.booksStore.save()
        }
        deleteAction.backgroundColor = UIColor(fromHex: 0xe74c3c)
        editActions.append(deleteAction)
        
        if selectedBook.readState == .toRead {
            editActions.append(updateReadStateAction(title: "Started", newReadState: .reading, actionColour: UIColor(fromHex: 0x3498db)))
        }
        else if selectedBook.readState == .reading {
            editActions.append(updateReadStateAction(title: "Finished", newReadState: .finished, actionColour: UIColor(fromHex: 0x2ecc71)))
        }
        
        return editActions
    }
}

/// DZNEmptyDataSetSource functions
extension BookTable : DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: resultsFilterer.showingSearchResults ? "fa-search" : "fa-book")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let titleText: String!
        if resultsFilterer.showingSearchResults {
            titleText = "No results"
        }
        else if readStates.contains(.reading) {
            titleText = "You are not reading any books!"
        }
        else {
            titleText = "You haven't yet finished a book. Get going!"
        }
        
        return NSAttributedString(string: titleText, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let descriptionText = resultsFilterer.showingSearchResults ? "Try changing your search." : "Add a book by clicking the + button above."
        
        return NSAttributedString(string: descriptionText, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)])
    }
}
