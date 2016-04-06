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

protocol BookSelectionDelegate: class {
    func bookSelected(book: Book)
}

class BookTableViewController: UITableViewController, UISearchResultsUpdating {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBAction func selectedSegmentChanged(sender: AnyObject) {
        if segmentControl.selectedSegmentIndex == 0 {
            readStates = [.ToRead, .Reading]
        }
        else{
            readStates = [.Finished]
        }
        updatePredicate([ReadStateFilter(states: readStates)])
        try! booksResultsController.performFetch()
        tableView.reloadData()
    }
    
    /// The currently selected read states
    var readStates = [BookReadState.ToRead, BookReadState.Reading]
    
    /// The books which this page displays
    var booksResultsController: NSFetchedResultsController!
    
    /// The delegate to handle book selection
    weak var bookSelectionDelegate: BookSelectionDelegate!
    
    /// The UISearchController to which this UITableViewController is connected.
    var searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        // Hacky way of getting some test data.
        self.loadDefaultDataIfFirstLaunch()
        
        // Setup the fetched results controller, attaching this TableViewController
        // as a delegate on it, and perform the initial fetch.
        booksResultsController = appDelegate.booksStore.FetchedBooksController()
        updatePredicate([ReadStateFilter(states: readStates)])
        try! booksResultsController.performFetch()
        
        // Setup the search bar.
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .Done
        self.tableView.tableHeaderView = searchController.searchBar
        
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
        updatePredicate([ReadStateFilter(states: readStates), TitleFilter(comparison: .Contains, text: searchController.searchBar.text!)])
        
        try! booksResultsController.performFetch()
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.booksResultsController.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell
        let cell = self.tableView.dequeueReusableCellWithIdentifier(String(BookTableViewCell), forIndexPath: indexPath) as! BookTableViewCell
        
        // Configure the cell from the corresponding book
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let selectedBook = bookAtIndexPath(indexPath){
            showSelectedBook(selectedBook)
        }
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as! String? {
            print("Restoring user activity with identifier \(identifier)")
            if let selectedBook = appDelegate.booksStore.GetBook(NSURL(string: identifier)!) {
                print("Restoring to book with title \(selectedBook.title)")
                showSelectedBook(selectedBook)
            }
        }
    }
    
    /// Shows the selected book in the details controller
    private func showSelectedBook(selectedBook: Book){
        if let bookDetailsController = self.bookSelectionDelegate as? BookDetailsViewController {
            bookDetailsController.bookSelected(selectedBook)
            splitViewController?.showDetailViewController(bookDetailsController, sender: nil)
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
            cell.bookCover!.image = UIImage(data: book.coverImage!)
        }
        else{
            cell.bookCover!.image = nil
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
        //return NSAttributedString(string: mode.emptyListTitleAndDescription.0, attributes: attrs)
        return NSAttributedString(string: "Empty", attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        //return NSAttributedString(string: mode.emptyListTitleAndDescription.1, attributes: attrs)
        return NSAttributedString(string: "Empty", attributes: attrs)
    }
}


extension BookTableViewController{
    func loadDefaultDataIfFirstLaunch() {
        let key = "hasLaunchedBefore"
        let launchedBefore = NSUserDefaults.standardUserDefaults().boolForKey(key)
        if launchedBefore == false {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)

            let booksToAdd: [(isbn: String, readState: BookReadState, titleDesc: String)] = [
                ("9780007232444", .Finished, "The Corrections"),
                ("9780099529125", .Finished, "Catch-22"),
                ("9780141187761", .Finished, "1984"),
                ("9780735611313", .Finished, "Code"),
                ("9780857282521", .ToRead, "The Entrepreneurial State"),
                ("9780330510936", .ToRead, "All the Pretty Horses"),
                ("9780006480419", .ToRead, "Neuromancer"),
                ("9780241950432", .Finished, "Catcher in the Rye"),
                ("9780099800200", .Finished, "Slaughterhouse 5"),
                ("9780006546061", .ToRead, "Farenheit 451"),
                ("9781442369054", .ToRead, "Steve Jobs"),
                ("9780007532766", .Finished, "Purity"),
                ("9780718197384", .Reading, "The Price of Inequality"),
                ("9780099889809", .Reading, "Something Happened"),
                ("9780241197790", .Finished, "The Trial"),
                ("9780340935125", .ToRead, "Indemnity Only"),
                ("9780857059994", .Finished, "The Girl in the Spider's Web"),
                ("9781846275951", .Finished, "Honourable Friends?"),
                ("9780141047973", .Finished, "23 Things They Don't Tell You About Capitalism"),
                ("9780330468466", .Finished, "The Road")
            ]
            
            for bookToAdd in booksToAdd {
                OnlineBookClient<GoogleBooksParser>.TryCreateBook(GoogleBooksRequest.Search(bookToAdd.isbn).url, readState: bookToAdd.readState, isbn13: bookToAdd.isbn, completionHandler:{
                        book in
                        self.reloadTable()
                    })
            }
        }
    }
    
    func reloadTable() {
        controllerDidChangeContent(self.booksResultsController)
    }
}