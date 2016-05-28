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
    
    var toReadStates: [BookReadState] {
        switch self {
        case .ToRead:
            return [.ToRead, .Reading]
        case .Finished:
            return [.Finished]
        }
    }
    
    static func fromReadState(state: BookReadState) -> TableSegmentOption{
        switch state{
        case .Finished:
            return .Finished
        default:
            return .ToRead
        }
    }
}

class BookTable: FetchedResultsTable {

    @IBOutlet weak var segmentControl: UISegmentedControl!

    /// The currently selected segment
    var selectedSegment = TableSegmentOption.ToRead
    
    /// The UISearchController to which this UITableViewController is connected.
    var searchController = UISearchController(searchResultsController: nil)
    
    var viewHasJustLoaded = true
    var tableViewScrollPositions = [TableSegmentOption: CGPoint]()
    
    override func viewDidLoad() {
        resultsController = appDelegate.booksStore.FetchedBooksController()
        cellIdentifier = String(BookTableViewCell)
        
        // We will manage the clearing of selections ourselves
        self.clearsSelectionOnViewWillAppear = false
        
        // Setup the search bar.
        configureSearchBar()
        
        // Attach this controller as a delegate on for the results controller, and set the initial predicate
        resultsController.delegate = self
        updatePredicate(ReadStateFilter(states: selectedSegment.toReadStates).ToPredicate())
        
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        // Also, setting the table footer removes the cell separators
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        tableView.tableFooterView = UIView()

        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Now that the view has appeared, store the current table view offset
        // as the starting scroll positions for each of the modes.
        if viewHasJustLoaded {
            let startingOffset = tableView.contentOffset
            tableViewScrollPositions[.ToRead] = startingOffset
            tableViewScrollPositions[.Finished] = startingOffset
        }
        viewHasJustLoaded = false
        
        // Deselect selected rows, so they don't stay highlighted
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
        
        super.viewDidAppear(animated)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if selectedSegment == .Finished {
            // We don't need a section title for this segment
            return nil
        }
        
        // Otherwise, turn the section name into a BookReadState and use its description property
        let sectionAsInt = Int32(self.resultsController.sections![section].name)!
        return BookReadState(rawValue: sectionAsInt)!.description
    }
    
    override func configureCell(cell: UITableViewCell, fromObject object: AnyObject) {
        (cell as! BookTableViewCell).configureFromBook(object as? Book)
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
    
        let delete = UITableViewRowAction(style: .Destructive, title: "Delete") {
            _, index in

            if let selectedBook = self.resultsController.objectAtIndexPath(index) as? Book {
                // If there is a book at this index, delete it
                appDelegate.booksStore.DeleteBookAndDeindex(selectedBook)
                
                // If it is being displayed, clear it
                if let bookDetails = appDelegate.splitViewController.bookDetailsControllerIfSplit where bookDetails.book == selectedBook {
                    bookDetails.ClearUI()
                }
            }
        }
        delete.backgroundColor = UIColor.redColor()
        return [delete]
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // All cells are "editable"
        return true
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            identifierUrl = NSURL(string: identifier),
            selectedBook = appDelegate.booksStore.GetBook(identifierUrl) {
            
            // Update the selected segment and table on display
            segmentControl.selectedSegmentIndex = TableSegmentOption.fromReadState(selectedBook.readState).rawValue
            //selectedSegmentChanged(self)

            // Show the book
            if let bookDetails = appDelegate.splitViewController.detailNavigationController?.topViewController as? BookDetails {
                bookDetails.book = selectedBook
                bookDetails.UpdateUi()
            }
            else {
                performSegueWithIdentifier("showDetail", sender: selectedBook)
            }
        }
    }
    
    @IBAction func selectedSegmentChanged(sender: AnyObject) {
        // Store the scroll position for the current read state
        tableViewScrollPositions[selectedSegment] = tableView.contentOffset
        
        // Update the read state to the selected read state
        selectedSegment = TableSegmentOption(rawValue: segmentControl.selectedSegmentIndex)!
        
        // Load the previously stored scroll position
        tableView.setContentOffset(tableViewScrollPositions[selectedSegment]!, animated: false)
        
        // Load the data
        updatePredicate(ReadStateFilter(states: selectedSegment.toReadStates).ToPredicate())
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addBook" {
            let navigationController = segue.destinationViewController as! NavWithReadState
            navigationController.readState = selectedSegment.toReadStates.first
        }
        else if segue.identifier == "showDetail" {
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
    }
}

/**
 Controls for the Search capabilities of the table.
 */
extension BookTable: UISearchResultsUpdating {
    func configureSearchBar() {
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .Done
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Offset by the height of the search bar, so as to hide it on load.
        // However, the contentOffset values will change before the view appears,
        // due to the adjusted scroll view inset from the navigation bar.
        self.tableView.setContentOffset(CGPointMake(0, searchController.searchBar.frame.height), animated: false)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        ReadStateFilter(states: selectedSegment.toReadStates).ToPredicate()
        updatePredicate(NSCompoundPredicate(andPredicateWithSubpredicates: [ReadStateFilter(states: selectedSegment.toReadStates).ToPredicate(), TitleFilter(comparison: .Contains, text: searchController.searchBar.text!).ToPredicate()]))
    }
}


/**
 Functions controlling the DZNEmptyDataSet.
 */
extension BookTable : DZNEmptyDataSetSource {
    
    private func IsShowingSearchResults() -> Bool {
        return searchController.active && searchController.searchBar.text?.isEmpty == false
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        if IsShowingSearchResults() {
            return UIImage(named: "fa-search")
        }
        return UIImage(named: "fa-book")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        if IsShowingSearchResults() {
            return NSAttributedString(string: "No results", attributes: attrs)
        }
        switch self.selectedSegment{
        case .ToRead:
            return NSAttributedString(string: "You are not reading any books!", attributes: attrs)
        case .Finished:
            return NSAttributedString(string: "You haven't yet finished a book. Get going!", attributes: attrs)
        }
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        if IsShowingSearchResults() {
            return NSAttributedString(string: "Try changing your search.", attributes: attrs)
        }
        return NSAttributedString(string: "Add a book by clicking the + button above.", attributes: attrs)
    }
}
