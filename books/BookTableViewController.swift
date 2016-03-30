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

class BookTableViewController: UITableViewController, UISearchResultsUpdating {
    
    /// The mode in which this BookTableViewController is operating.
    var mode: BookTableViewMode!
    
    /// The books which this page displays
    var booksResultsController: NSFetchedResultsController!
    
    /// The UISearchController to which this UITableViewController is connected.
    var searchController = UISearchController(searchResultsController: nil)
    
    var selectedBook: Book!
    
    override func viewDidLoad() {
        self.definesPresentationContext = true
        
        // Set the mode variable
        mode = BookTableViewMode.modeFromTabIndex(self.tabBarController!.selectedIndex)
        
        // Setup the fetched results controller, attaching this TableViewController
        // as a delegate on it, and perform the initial fetch.
        booksResultsController = appDelegate.booksStore.FetchedBooksController()
        updatePredicate([ReadStateFilter(state: mode.equivalentBookReadState)])
        try! booksResultsController.performFetch()
        
        // Setup the search bar.
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .Done
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Set the title accordingly.
        self.navigationItem.title = mode.title
        
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // This removes the cell separators
        tableView.tableFooterView = UIView()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        // Reload the data every time, since other views can send things into this view
        try! booksResultsController.performFetch()
        tableView.reloadData()
        
        // If there is a selected row when the view is going to be shown, deselect it.
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
    }
    
    private func updatePredicate(filters: [BookFilter]){
        booksResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: filters.map{ $0.ToPredicate() })
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        updatePredicate([ReadStateFilter(state: mode.equivalentBookReadState), TitleFilter(comparison: .Contains, text: searchController.searchBar.text!)])
        try! booksResultsController.performFetch()
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.booksResultsController.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell
        let cell = self.tableView.dequeueReusableCellWithIdentifier("BookTableViewCell", forIndexPath: indexPath) as! BookTableViewCell
        
        // Configure the cell from the corresponding book
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedBook = bookAtIndexPath(indexPath)
        performSegueWithIdentifier("detailsSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailsSegue" {
            let bookDetailsController = segue.destinationViewController as! BookDetailsViewController
            bookDetailsController.hidesBottomBarWhenPushed = true
            bookDetailsController.book = selectedBook
        }
        else if segue.identifier == "addBookSegue" {
            let addBookController = (segue.destinationViewController as! UINavigationController).viewControllers.first as! ScannerViewController
            addBookController.bookReadState = mode.equivalentBookReadState
        }
        
        super.prepareForSegue(segue, sender: sender)
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as! String? {
            print("Restoring user activity with identifier \(identifier)")
            selectedBook = appDelegate.booksStore.GetBook(NSURL(string: identifier)!)
            if selectedBook != nil {
                print("Restoring to book with title \(selectedBook.title)")
                self.navigationController?.popToRootViewControllerAnimated(false)
                self.performSegueWithIdentifier("detailsSegue", sender: self)
            }
        }
    }
    
    /// Gets the specified object from the results controller, casted to a Book
    private func bookAtIndexPath(indexPath: NSIndexPath) -> Book? {
        return booksResultsController.objectAtIndexPath(indexPath) as? Book
    }
    
    /// Configures the text labels on the UICell according to the book at the specified index path
    private func configureCell(cell: BookTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let book = self.booksResultsController.objectAtIndexPath(indexPath) as! Book
        cell.titleLabel!.text = book.title
        cell.authorsLabel!.text = book.authorList
        if book.coverImage != nil {
            cell.bookImageView!.image = UIImage(data: book.coverImage!)
        }
    }
}


// Standard fetched results controller delegate code
extension BookTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let _ = try? controller.performFetch()
        self.tableView.reloadData()
        self.tableView.endUpdates()
    }
    
    /// Handles any change in the data managed by the controller
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            switch type {
            case .Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .None)
            case .Update:
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath!){
                    self.configureCell(cell as! BookTableViewCell, atIndexPath: indexPath!)
                    self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                }
            case .Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
            }
    }
}

/**
 Functions controlling the DZNEmptyDataSet.
 */
extension BookTableViewController : DZNEmptyDataSetSource {
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "book_stack")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: mode.emptyListTitleAndDescription.0, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: mode.emptyListTitleAndDescription.1, attributes: attrs)
    }
}


/**
 The possible modes in which the BookTableViewController can be used.
 */
enum BookTableViewMode {
    
    case Reading
    case ToRead
    case Finished
    
    /// A heading and description to use when the book list is empty
    var emptyListTitleAndDescription: (String, String) {
        switch self{
        case Reading:
            return ("You aren't reading any books", "Add a new book, or start reading one of your to-read books.")
        case ToRead:
            return ("You don't have any books on your to-read list", "Why not search for some books to read? Just click Search.")
        case Finished:
            return ("You haven't finished any books", "Or, at least, you haven't added any to this list. Want to get started?")
        }
    }
    
    /// The string to use as the title of the page when it is in this mode.
    var title: String {
        switch self{
        case Reading:
            return "Currently Reading"
        case ToRead:
            return "To Read"
        case Finished:
            return "Finished"
        }
    }
    
    /// The core data book read state corresponding to this mode
    var equivalentBookReadState: BookReadState {
        switch self{
        case .Reading:
            return BookReadState.Reading
        case .ToRead:
            return BookReadState.ToRead
        case .Finished:
            return BookReadState.Finished
        }
    }
    
    static func modeFromTabIndex(tabIndex: Int) -> BookTableViewMode{
        switch tabIndex{
        case ToReadTabIndex:
            return BookTableViewMode.ToRead
        case ReadingTabIndex:
            return BookTableViewMode.Reading
        case FinishedTabIndex:
            return BookTableViewMode.Finished
        default:
            print("Unrecognised index: \(tabIndex)")
            return BookTableViewMode.ToRead
        }
    }
}