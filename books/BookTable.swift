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
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        resultsFilterer = FetchedResultsFilterer(uiSearchController: searchController, tableView: self.tableView, fetchedResultsController: resultsController, predicateBuilder: predicateBuilder)

        
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        // Also, we will manage the clearing of selections ourselves. Setting the table footer removes the cell separators
        //navigationController!.view.backgroundColor = UIColor.white
        navigationItem.leftBarButtonItem = editButtonItem
        clearsSelectionOnViewWillAppear = false
        tableView.allowsMultipleSelectionDuringEditing = true
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

    @IBAction func addWasPressed(_ sender: AnyObject) {
        func segueAction(title: String, identifier: String) -> UIAlertAction {
            return UIAlertAction(title: title, style: .default){_ in
                self.performSegue(withIdentifier: identifier, sender: self)
            }
        }

        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        optionsAlert.addAction(segueAction(title: "Enter Manually", identifier: "addManuallySegue"))
        optionsAlert.addAction(segueAction(title: "Search Online", identifier: "searchByTextSegue"))
        optionsAlert.addAction(segueAction(title: "Scan Barcode", identifier: "scanBarcodeSegue"))
#if DEBUG
        optionsAlert.addAction(UIAlertAction(title: "Add Test Data", style: .default){ _ in
            TestData.loadTestData()
        })
#endif
        
        // For iPad, set the popover presentation controller's source
        if let popPresenter = optionsAlert.popoverPresentationController {
            popPresenter.sourceView = sender.view
            popPresenter.sourceRect = sender.view.bounds
        }
        
        self.present(optionsAlert, animated: true, completion: nil)
    }
    

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Turn the section name into a BookReadState and use its description property
        let sectionAsInt = Int32(self.resultsController.sections![section].name)!
        return BookReadState(rawValue: sectionAsInt)!.description
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let identifierUrl = URL(string: identifier),
            let selectedBook = appDelegate.booksStore.get(bookIdUrl: identifierUrl) else { return }

        // Update the selected segment, which will reload the table, and dismiss the search if there is one
        //selectedSegment = TableSegmentOption.fromReadState(selectedBook.readState)
        resultsFilterer.dismissSearch()
        
        // Select the corresponding row and scroll it in to view.
        if let indexPathOfSelectedBook = self.resultsController.indexPath(forObject: selectedBook) {
            self.tableView.scrollToRow(at: indexPathOfSelectedBook, at: .none, animated: false)
            self.tableView.selectRow(at: indexPathOfSelectedBook, animated: false, scrollPosition: .none)
        }
        
        // Check whether the detail view is already displayed, and update the book it is showing.
        if let bookDetails = appDelegate.splitViewController.detailNavigationController?.topViewController as? BookDetails {
            bookDetails.updateDisplayedBook(selectedBook)
        }
        else {
            // Otherwise, segue to the details view. This will be the case when, in compact width,
            // this table is at the top of the navigation stack.
            self.performSegue(withIdentifier: "showDetail", sender: selectedBook)
        }
        
        self.presentedViewController?.dismiss(animated: false, completion: nil)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navWithReadState = segue.destination as? NavWithReadState {
            navWithReadState.readState = readStates.first!
        }
        else if let destinationViewController = (segue.destination as? UINavigationController)?.topViewController as? BookDetails {

            if isEditing {
                return
            }

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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // All cells are "editable"
        return true
    }
    /*
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // We can reorder the "ToRead" books
        return selectedSegment == .toRead && indexPath.section == 1
    }*/
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        else {
            return IndexPath(row: 0, section: 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // We should only have movement in section 1. We also ignore moves which have no effect
        guard sourceIndexPath.section == 1 && destinationIndexPath.section == 1 else { return }
        guard sourceIndexPath.row != destinationIndexPath.row else { return }
        
        // Calculate the ordering of the two rows involved
        let itemMovedDown = sourceIndexPath.row < destinationIndexPath.row
        let firstRow = itemMovedDown ? sourceIndexPath.row : destinationIndexPath.row
        let lastRow = itemMovedDown ? destinationIndexPath.row : sourceIndexPath.row
        
        // Move the objects to reflect the rows
        var objectsInSection = resultsController.sections![1].objects!
        let movedObj = objectsInSection.remove(at: sourceIndexPath.row)
        objectsInSection.insert(movedObj, at: destinationIndexPath.row)
        
        // Update the model to reflect the objects's positions
        for rowNumber in firstRow...lastRow {
            (objectsInSection[rowNumber] as! Book).sort = rowNumber as NSNumber?
        }
        
        // Turn off updates while we save the object context
        tableUpdater.withoutUpdates {
            appDelegate.booksStore.save()
            try! resultsController.performFetch()
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            appDelegate.booksStore.delete(resultsController.object(at: indexPath))
            appDelegate.booksStore.save()
        }
    }
}
