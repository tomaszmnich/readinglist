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
    case ToRead = 0
    case Finished = 1
    
    var readStates: [BookReadState] {
        return self == .ToRead ? [.ToRead, .Reading] : [.Finished]
    }
    
    func toPredicate() -> NSPredicate {
        return NSPredicate.Or(self.readStates.map{BookPredicate.readStateEqual($0)})
    }
    
    static func fromReadState(state: BookReadState) -> TableSegmentOption {
        return state == .Finished ? .Finished : .ToRead
    }
}

class BookTable: FilteredFetchedResultsTable {
    
    override func viewDidLoad() {
        resultsController = appDelegate.booksStore.FetchedBooksController(selectedSegment.toPredicate(), initialSortDescriptors: [BookPredicate.readStateSort, NSSortDescriptor(key: "sort", ascending: true), NSSortDescriptor(key: "startedReading", ascending: true), NSSortDescriptor(key: "finishedReading", ascending: true)])
        cellIdentifier = String(BookTableViewCell)
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        // Also, we will manage the clearing of selections ourselves. Setting the table footer removes the cell separators
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        self.clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView()
        
        navigationItem.leftBarButtonItem = editButtonItem()
        tableView.allowsMultipleSelectionDuringEditing = true
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        // If we haven't initialised the scroll positions dictionary, do so now, for all
        // tabs, with the current scroll position (which will be the starting position).
        if tableViewScrollPositions == nil {
            tableViewScrollPositions = [.ToRead: tableView.contentOffset, .Finished: tableView.contentOffset]
        }
        
        // Deselect selected rows, so they don't stay highlighted
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        tableViewScrollPositions![selectedSegment] = tableView.contentOffset
    }
    
    @IBOutlet weak var segmentControl: UISegmentedControl!

    @IBAction func addWasPressed(sender: AnyObject) {
        // We are going to show an action sheet
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        optionsAlert.addAction(UIAlertAction(title: "Enter Manually", style: .Default) {
            _ in
            self.performSegueWithIdentifier("addManuallySegue", sender: self)
        })
        optionsAlert.addAction(UIAlertAction(title: "Search Online", style: .Default) {
            _ in
            self.performSegueWithIdentifier("searchByTextSegue", sender: self)
        })
        optionsAlert.addAction(UIAlertAction(title: "Scan Barcode", style: .Default){
            _ in
            self.performSegueWithIdentifier("scanBarcodeSegue", sender: self)
        })
        #if DEBUG
            optionsAlert.addAction(UIAlertAction(title: "Add Test Data", style: .Default){
                _ in
                TestData.loadTestData()
            })
        #endif
        
        self.presentViewController(optionsAlert, animated: true, completion: nil)
    }
    
    /// The currently selected segment
    var selectedSegment = TableSegmentOption.ToRead {
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

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if selectedSegment == .Finished { return nil }
        
        // Otherwise, turn the section name into a BookReadState and use its description property
        let sectionAsInt = Int32(self.resultsController.sections![section].name)!
        return BookReadState(rawValue: sectionAsInt)!.description
    }
    
    override func configureCell(cell: UITableViewCell, fromObject object: AnyObject) {
        (cell as! BookTableViewCell).configureFromBook(object as! Book)
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            identifierUrl = NSURL(string: identifier),
            selectedBook = appDelegate.booksStore.GetBook(identifierUrl) else { return }

        // Update the selected segment, which will reload the table, and dismiss the search if there is one
        selectedSegment = TableSegmentOption.fromReadState(selectedBook.readState)
        dismissSearch()
        
        // Select the corresponding row and scroll it in to view.
        if let indexPathOfSelectedBook = self.resultsController.indexPathForObject(selectedBook) {
            self.tableView.scrollToRowAtIndexPath(indexPathOfSelectedBook, atScrollPosition: .None, animated: false)
            self.tableView.selectRowAtIndexPath(indexPathOfSelectedBook, animated: false, scrollPosition: .None)
        }
        
        // Check whether the detail view is already displayed, and update the book it is showing.
        if let bookDetails = appDelegate.splitViewController.detailNavigationController?.topViewController as? BookDetails {
            bookDetails.updateDisplayedBook(selectedBook)
        }
        else {
            // Otherwise, segue to the details view. This will be the case when, in compact width,
            // this table is at the top of the navigation stack.
            self.performSegueWithIdentifier("showDetail", sender: selectedBook)
        }
        
        self.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func selectedSegmentChanged(sender: AnyObject) {
        
        // Update the read state to the selected read state
        selectedSegment = TableSegmentOption(rawValue: segmentControl.selectedSegmentIndex)!
        
        // If there is a Book currently displaying on the split Detail view, select the corresponding row if possible
        if let currentlyShowingBook = appDelegate.splitViewController.bookDetailsControllerIfSplit?.book where selectedSegment.readStates.contains(currentlyShowingBook.readState) {
            
            tableView.selectRowAtIndexPath(self.resultsController.indexPathForObject(currentlyShowingBook), animated: false, scrollPosition: .None)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !tableView.editing {
            performSegueWithIdentifier("showDetail", sender: self.resultsController.objectAtIndexPath(indexPath) as? Book)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let destinationViewController = (segue.destinationViewController as! UINavigationController).topViewController as! BookDetails

            // The sender is a Book if we are restoring state
            if let bookSender = sender as? Book {
                destinationViewController.book = bookSender
            }
            else if let cellSender = sender as? UITableViewCell,
                selectedIndex = self.tableView.indexPathForCell(cellSender) {
                destinationViewController.book = self.resultsController.objectAtIndexPath(selectedIndex) as? Book
            }
        }
        else if segue.identifier == "scanBarcodeSegue" || segue.identifier == "addManuallySegue" {
            (segue.destinationViewController as! NavWithReadState).readState = selectedSegment.readStates.first
        }
    }
    
    override func predicateForSearchText(searchText: String) -> NSPredicate {
        var predicate = selectedSegment.toPredicate()
        if !searchText.isEmptyOrWhitespace() && searchText.trim().characters.count >= 2 {
            predicate = predicate.And(BookPredicate.searchInTitleOrAuthor(searchText))
        }
        return predicate
    }
}

/// Editing logic.
extension BookTable {

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        // For safety check that there is a Book here
        guard let selectedBook = self.resultsController.objectAtIndexPath(indexPath) as? Book else { return nil }
        
        let delete = UITableViewRowAction(style: .Destructive, title: "Delete") { _, _ in
            // If there is a book at this index, delete it
            appDelegate.booksStore.DeleteBookAndDeindex(selectedBook)
        }
        delete.backgroundColor = UIColor.redColor()
        var editActions = [delete]
        
        if selectedBook.readState == .ToRead {
            editActions.append(UITableViewRowAction(style: .Normal, title: "Start") { _, _ in
                selectedBook.readState = .Reading
                selectedBook.startedReading = NSDate()
                appDelegate.booksStore.UpdateSpotlightIndex(selectedBook)
                self.tableView.setEditing(false, animated: true)
            })
        }
        if selectedBook.readState == .Reading {
            editActions.append(UITableViewRowAction(style: .Normal, title: "Finish") { _, _ in
                selectedBook.readState = .Finished
                selectedBook.finishedReading = NSDate()
                appDelegate.booksStore.UpdateSpotlightIndex(selectedBook)
                self.tableView.setEditing(false, animated: true)
            })
        }
        
        return editActions
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // All cells are "editable"; just for safety check that there is a Book there
        return self.resultsController.objectAtIndexPath(indexPath) is Book
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // We can reorder the "ToRead" books
        return selectedSegment == .ToRead && indexPath.section == 1
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        else {
            return NSIndexPath(forRow: 0, inSection: 1)
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
        // We should only have movement in section 1. We also ignore moves which have no effect
        guard sourceIndexPath.section == 1 && destinationIndexPath.section == 1 else { return }
        guard sourceIndexPath.row != destinationIndexPath.row else { return }
        
        // Calculate the ordering of the two rows involved
        let itemMovedDown = sourceIndexPath.row < destinationIndexPath.row
        let firstRow = itemMovedDown ? sourceIndexPath.row : destinationIndexPath.row
        let lastRow = itemMovedDown ? destinationIndexPath.row : sourceIndexPath.row
        
        // Move the objects to reflect the rows
        var objectsInSection = resultsController.sections![1].objects!
        let movedObj = objectsInSection.removeAtIndex(sourceIndexPath.row)
        objectsInSection.insert(movedObj, atIndex: destinationIndexPath.row)
        
        // Update the model to reflect the objects's positions
        for rowNumber in firstRow...lastRow {
            (objectsInSection[rowNumber] as! Book).sort = rowNumber
        }
        
        // Turn off updates while we save the object context
        toggleUpdates(on: false)
        
        appDelegate.booksStore.Save()
        refetch(reloadTable: false)
        
        toggleUpdates(on: true)
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            appDelegate.booksStore.DeleteBookAndDeindex(resultsController.objectAtIndexPath(indexPath) as! Book)
            appDelegate.booksStore.Save()
        }
    }
}


/**
 Functions controlling the DZNEmptyDataSet.
 */
extension BookTable : DZNEmptyDataSetSource {
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: isShowingSearchResults() ? "fa-search" : "fa-book")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let titleText: String!
        if isShowingSearchResults() {
            titleText = "No results"
        }
        else {
            titleText = self.selectedSegment == .ToRead ? "You are not reading any books!" : "You haven't yet finished a book. Get going!"
        }
        
        return NSAttributedString(string: titleText, attributes: [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)])
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let descriptionText = isShowingSearchResults() ? "Try changing your search." : "Add a book by clicking the + button above."
        
        return NSAttributedString(string: descriptionText, attributes: [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)])
    }
}
