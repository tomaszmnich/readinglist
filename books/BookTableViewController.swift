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

class BookTableViewController: UITableViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    /// The controller to get the results to display in this view
    var resultsController = appDelegate.booksStore.FetchedBooksController()
    
    /// The currently selected read state
    var readState = BookReadState.Reading
    
    /// The delegate to handle book selection
    weak var bookSelectionDelegate: BookSelectionDelegate!
    
    /// The UISearchController to which this UITableViewController is connected.
    var searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        // Set the results controller
        updatePredicate([ReadStateFilter(states: [readState])])
        
        // Attach this controller as a delegate on for the results controller, and perform the initial fetch.
        resultsController.delegate = self
        try! resultsController.performFetch()
        
        // Hacky way of getting some test data.
        self.loadDefaultDataIfFirstLaunch()
        
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
    
    private func updatePredicate(filters: [BookFilter]){
        resultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: filters.map{ $0.ToPredicate() })
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultsController.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell, configure the cell for the specified index path and return it
        let cell = tableView.dequeueReusableCellWithIdentifier(String(BookTableViewCell), forIndexPath: indexPath) as! BookTableViewCell
        configureCell(cell, fromResult: resultsController.objectAtIndexPath(indexPath) as? Book)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let selectedBook = resultsController.objectAtIndexPath(indexPath) as? Book {
            showSelectedBook(selectedBook)
        }
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as! String? {
            if let selectedBook = appDelegate.booksStore.GetBook(NSURL(string: identifier)!) {
                showSelectedBook(selectedBook)
            }
        }
    }
    
    private func configureCell(cell: BookTableViewCell, fromResult result: Book?){
        cell.titleLabel!.text = result?.title
        cell.authorsLabel!.text = result?.authorList
        cell.bookCover!.image = result?.coverImage != nil ? UIImage(data: result!.coverImage!) : nil
    }
    
    /// Shows the selected book in the details controller
    private func showSelectedBook(selectedBook: Book){
        if let bookDetailsController = self.bookSelectionDelegate as? BookDetailsViewController {
            bookDetailsController.bookSelected(selectedBook)
            splitViewController?.showDetailViewController(bookDetailsController, sender: nil)
        }
    }
    
    @IBAction func selectedSegmentChanged(sender: AnyObject) {
        switch segmentControl.selectedSegmentIndex{
        case 2:
            readState = .Finished
        case 1:
            readState = .ToRead
        default:
            readState = .Reading
        }
        updatePredicate([ReadStateFilter(states: [readState])])
        try! resultsController.performFetch()
        tableView.reloadData()
    }
}


/**
 The handling of updates from the fetched results controller.
*/
extension BookTableViewController: NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        try! controller.performFetch()
        tableView.reloadData()
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? BookTableViewCell {
                configureCell(cell, fromResult: resultsController.objectAtIndexPath(indexPath!) as? Book)
            }
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .None)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
        }
    }
}

extension BookTableViewController: UISearchResultsUpdating{
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        updatePredicate([ReadStateFilter(states: [readState]), TitleFilter(comparison: .Contains, text: searchController.searchBar.text!)])
        try! resultsController.performFetch()
        tableView.reloadData()
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
                        self.tableView.reloadData()
                    })
            }
        }
    }
}