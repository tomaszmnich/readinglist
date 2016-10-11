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

enum TableSegmentOption: Int {
    case toRead = 0
    case finished = 1
    
    var readStates: [BookReadState] {
        return self == .toRead ? [.toRead, .reading] : [.finished]
    }
    
    func toPredicate() -> NSPredicate {
        return NSPredicate.Or(self.readStates.map{BookPredicate.readStateEqual($0)})
    }
    
    static func fromReadState(_ state: BookReadState) -> TableSegmentOption {
        return state == .finished ? .finished : .toRead
    }
}

class BookTable: FilteredFetchedResultsTable {
    
    var innerController: NSFetchedResultsController<Book>!
    
    override var resultsController: NSFetchedResultsController<NSFetchRequestResult>! {
        get {
            return innerController as! NSFetchedResultsController<NSFetchRequestResult>
        }
    }
    
    override func viewDidLoad() {
        // Set up the results controller
        innerController = appDelegate.booksStore.FetchedBooksController(selectedSegment.toPredicate(), initialSortDescriptors: [BookPredicate.readStateSort, NSSortDescriptor(key: "sort", ascending: true), NSSortDescriptor(key: "startedReading", ascending: true), NSSortDescriptor(key: "finishedReading", ascending: true)])
        innerController.delegate = self
        
        cellIdentifier = String(describing: BookTableViewCell.self)
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        // Also, we will manage the clearing of selections ourselves. Setting the table footer removes the cell separators
        self.navigationController!.view.backgroundColor = UIColor.white
        self.clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView()
        
        navigationItem.leftBarButtonItem = editButtonItem
        tableView.allowsMultipleSelectionDuringEditing = true
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // If we haven't initialised the scroll positions dictionary, do so now, for all
        // tabs, with the current scroll position (which will be the starting position).
        if tableViewScrollPositions == nil {
            tableViewScrollPositions = [.toRead: tableView.contentOffset, .finished: tableView.contentOffset]
        }
        
        // Deselect selected rows, so they don't stay highlighted
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tableViewScrollPositions![selectedSegment] = tableView.contentOffset
    }
    
    @IBOutlet weak var segmentControl: UISegmentedControl!

    @IBAction func addWasPressed(_ sender: AnyObject) {
        // We are going to show an action sheet
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        optionsAlert.addAction(UIAlertAction(title: "Enter Manually", style: .default) {
            _ in
            self.performSegue(withIdentifier: "addManuallySegue", sender: self)
        })
        optionsAlert.addAction(UIAlertAction(title: "Search Online", style: .default) {
            _ in
            self.performSegue(withIdentifier: "searchByTextSegue", sender: self)
        })
        optionsAlert.addAction(UIAlertAction(title: "Scan Barcode", style: .default){
            _ in
            self.performSegue(withIdentifier: "scanBarcodeSegue", sender: self)
        })
        #if DEBUG
            optionsAlert.addAction(UIAlertAction(title: "Add Test Data", style: .default){
                _ in
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
    
    /// The currently selected segment
    var selectedSegment = TableSegmentOption.toRead {
        didSet {
            guard selectedSegment != oldValue else { return }
            
            // If the view is visible, save the scroll position
            if self.view.window != nil {
                
                // Store the scroll position for the old read state
                tableViewScrollPositions![oldValue] = tableView.contentOffset
            
                // If we have a position in the dictionary for the new segment state, scroll to that
                if let newPosition = tableViewScrollPositions![selectedSegment] {
                    tableView.setContentOffset(newPosition, animated: false)
                }
            }
            
            // Update the selected segment index. This may have already been done, but never mind.
            segmentControl.selectedSegmentIndex = selectedSegment.rawValue
            
            // Update the predicate
            updatePredicateAndReloadTable(selectedSegment.toPredicate())
        }
    }
    
    /// The stored scroll positions to allow our single table to function like two tables
    var tableViewScrollPositions: [TableSegmentOption: CGPoint]?

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if selectedSegment == .finished { return nil }
        
        // Otherwise, turn the section name into a BookReadState and use its description property
        let sectionAsInt = Int32(self.resultsController.sections![section].name)!
        return BookReadState(rawValue: sectionAsInt)!.description
    }
    
    override func configureCell(_ cell: UITableViewCell, fromObject object: AnyObject) {
        (cell as! BookTableViewCell).configureFromBook(object as! Book)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let identifierUrl = URL(string: identifier),
            let selectedBook = appDelegate.booksStore.GetBook(identifierUrl) else { return }

        // Update the selected segment, which will reload the table, and dismiss the search if there is one
        selectedSegment = TableSegmentOption.fromReadState(selectedBook.readState)
        dismissSearch()
        
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
    
    @IBAction func selectedSegmentChanged(_ sender: AnyObject) {
        
        // Update the read state to the selected read state
        selectedSegment = TableSegmentOption(rawValue: segmentControl.selectedSegmentIndex)!
        
        // If there is a Book currently displaying on the split Detail view, select the corresponding row if possible
        if let currentlyShowingBook = appDelegate.splitViewController.bookDetailsControllerIfSplit?.book,
            selectedSegment.readStates.contains(currentlyShowingBook.readState) {
            
            tableView.selectRow(at: self.resultsController.indexPath(forObject: currentlyShowingBook), animated: false, scrollPosition: .none)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navWithReadState = segue.destination as? NavWithReadState {
            navWithReadState.readState = selectedSegment.readStates.first
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
                destinationViewController.book = self.resultsController.object(at: selectedIndex) as? Book
            }
        }
    }
    
    override func predicateForSearchText(_ searchText: String) -> NSPredicate {
        var predicate = selectedSegment.toPredicate()
        if !searchText.isEmptyOrWhitespace() && searchText.trim().characters.count >= 2 {
            predicate = predicate.And(BookPredicate.searchInTitleOrAuthor(searchText))
        }
        return predicate
    }
}

/// Editing logic.
extension BookTable {

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // For safety check that there is a Book here
        guard let selectedBook = self.resultsController.object(at: indexPath) as? Book else { return nil }
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { _, _ in
            // If there is a book at this index, delete it
            appDelegate.booksStore.DeleteBookAndDeindex(selectedBook)
        }
        delete.backgroundColor = UIColor(fromHex: 0xe74c3c)
        var editActions = [delete]
        
        if selectedBook.readState == .toRead {
            let startedAction = UITableViewRowAction(style: .normal, title: "Started") { _, _ in
                selectedBook.readState = .reading
                selectedBook.startedReading = Date()
                appDelegate.booksStore.UpdateSpotlightIndex(selectedBook)
                self.tableView.setEditing(false, animated: true)
            }
            startedAction.backgroundColor = UIColor(fromHex: 0x3498db)
            editActions.append(startedAction)
        }
        if selectedBook.readState == .reading {
            let finishedAction = UITableViewRowAction(style: .normal, title: "Finished") { _, _ in
                selectedBook.readState = .finished
                selectedBook.finishedReading = Date()
                appDelegate.booksStore.UpdateSpotlightIndex(selectedBook)
                self.tableView.setEditing(false, animated: true)
            }
            finishedAction.backgroundColor = UIColor(fromHex: 0x2ecc71)
            editActions.append(finishedAction)
        }
        
        return editActions
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // All cells are "editable"; just for safety check that there is a Book there
        return self.resultsController.object(at: indexPath) is Book
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // We can reorder the "ToRead" books
        return selectedSegment == .toRead && (indexPath as NSIndexPath).section == 1
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if (sourceIndexPath as NSIndexPath).section == (proposedDestinationIndexPath as NSIndexPath).section {
            return proposedDestinationIndexPath
        }
        else {
            return IndexPath(row: 0, section: 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // We should only have movement in section 1. We also ignore moves which have no effect
        guard (sourceIndexPath as NSIndexPath).section == 1 && (destinationIndexPath as NSIndexPath).section == 1 else { return }
        guard (sourceIndexPath as NSIndexPath).row != (destinationIndexPath as NSIndexPath).row else { return }
        
        // Calculate the ordering of the two rows involved
        let itemMovedDown = (sourceIndexPath as NSIndexPath).row < (destinationIndexPath as NSIndexPath).row
        let firstRow = itemMovedDown ? (sourceIndexPath as NSIndexPath).row : (destinationIndexPath as NSIndexPath).row
        let lastRow = itemMovedDown ? (destinationIndexPath as NSIndexPath).row : (sourceIndexPath as NSIndexPath).row
        
        // Move the objects to reflect the rows
        var objectsInSection = resultsController.sections![1].objects!
        let movedObj = objectsInSection.remove(at: (sourceIndexPath as NSIndexPath).row)
        objectsInSection.insert(movedObj, at: (destinationIndexPath as NSIndexPath).row)
        
        // Update the model to reflect the objects's positions
        for rowNumber in firstRow...lastRow {
            (objectsInSection[rowNumber] as! Book).sort = rowNumber as NSNumber?
        }
        
        // Turn off updates while we save the object context
        toggleUpdates(on: false)
        
        appDelegate.booksStore.Save()
        refetch(reloadTable: false)
        
        toggleUpdates(on: true)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            appDelegate.booksStore.DeleteBookAndDeindex(resultsController.object(at: indexPath) as! Book)
            appDelegate.booksStore.Save()
        }
    }
}


/**
 Functions controlling the DZNEmptyDataSet.
 */
extension BookTable : DZNEmptyDataSetSource {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: isShowingSearchResults() ? "fa-search" : "fa-book")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let titleText: String!
        if isShowingSearchResults() {
            titleText = "No results"
        }
        else {
            titleText = self.selectedSegment == .toRead ? "You are not reading any books!" : "You haven't yet finished a book. Get going!"
        }
        
        return NSAttributedString(string: titleText, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)])
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let descriptionText = isShowingSearchResults() ? "Try changing your search." : "Add a book by clicking the + button above."
        
        return NSAttributedString(string: descriptionText, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)])
    }
}
