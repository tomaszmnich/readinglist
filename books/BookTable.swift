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
    private var readStatePredicate: NSPredicate!
    
    override func viewDidLoad() {
        readStatePredicate = NSPredicate.Or(readStates.map{BookPredicate.readState(equalTo: $0)})
        
        // Set up the results controller
        resultsController = appDelegate.booksStore.fetchedResultsController(readStatePredicate, initialSortDescriptors: [BookPredicate.readStateSort, NSSortDescriptor(key: "sort", ascending: true), NSSortDescriptor(key: "startedReading", ascending: true), NSSortDescriptor(key: "finishedReading", ascending: true)])
    
        // Assign the table updator, which will deal with changes to the data
        tableUpdater = TableUpdater<Book, BookTableViewCell>(table: tableView, controller: resultsController)
        
        /// The UISearchController to which this UITableViewController will be connected.
        let searchController = UISearchController(searchResultsController: nil)
        let predicateBuilder = BookPredicateBuilder(readStatePredicate: self.readStatePredicate)
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
        // Dismiss the search if there is one
        resultsFilterer.dismissSearch()
        
        // Select the corresponding row and scroll it in to view.
        if let indexPathOfSelectedBook = self.resultsController.indexPath(forObject: book) {
            self.tableView.scrollToRow(at: indexPathOfSelectedBook, at: .none, animated: false)
            self.tableView.selectRow(at: indexPathOfSelectedBook, animated: false, scrollPosition: .none)
        }
        
        // Check whether the detail view is already displayed, and update the book it is showing.
        /*if let bookDetails = appDelegate.splitViewController.detailNavigationController?.topViewController as? BookDetails {
         bookDetails.updateDisplayedBook(selectedBook)
         }
         else {*/
        // Otherwise, segue to the details view. This will be the case when, in compact width,
        // this table is at the top of the navigation stack.
        self.performSegue(withIdentifier: "showDetail", sender: book)
        //}
        
        self.presentedViewController?.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = (segue.destination as? UINavigationController)?.topViewController as? BookDetails {
            // The sender is a Book if we are restoring state
            if let bookSender = sender as? Book {
                destinationViewController.book = bookSender
            }
            else if let cellSender = sender as? UITableViewCell,
                let selectedIndex = self.tableView.indexPath(for: cellSender) {
                destinationViewController.book = self.resultsController.object(at: selectedIndex)
            }
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
        if selectedBook.readState == .reading {
            editActions.append(updateReadStateAction(title: "Finished", newReadState: .finished, actionColour: UIColor(fromHex: 0x2ecc71)))
        }
        
        return editActions
    }
}
