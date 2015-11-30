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

class BookTableViewController: UITableViewController {
    
    /// The mode in which this BookTableViewController is operating.
    var mode: BookTableViewMode!
    
    /// The books which this page displays
    var booksResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        // Set the mode variable
        switch self.tabBarController!.selectedIndex{
        case ToReadTabIndex:
            mode = BookTableViewMode.ToRead
        case ReadingTabIndex:
            mode = BookTableViewMode.Reading
        case FinishedTabIndex:
            mode = BookTableViewMode.Finished
        default:
            print("Unrecognised tab index: \(self.tabBarController!.selectedIndex)")
        }
        
        // Setup the fetched results controller, attaching this TableViewController
        // as a delegate on it, and perform the initial fetch.
        booksResultsController = appDelegate().booksStore.fetchedBooksController(mode.equivalentBookReadState)
        booksResultsController.delegate = self
        let _ = try? booksResultsController.performFetch()
        
        // Set the title accordinly
        self.navigationItem.title = mode.title
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // This removes the cell separators
        tableView.tableFooterView = UIView()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
        super.viewWillAppear(animated)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.booksResultsController.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        // Configure the cell from the corresponding book
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // "detailsSegue" is for viewing a specific book
        if segue.identifier == "detailsSegue" {
            if let clickedCell = sender as? UITableViewCell {
                // Get the controller for viewing a book
                let bookDetailsController = segue.destinationViewController as! BookDetailsViewController

                // Set the book on the controller from the book corresponding to the clicked cell
                bookDetailsController.book = bookAtIndexPath(tableView.indexPathForCell(clickedCell)!)
            }
        }
        if segue.identifier == "addBookSegue"{
            let addBookController = (segue.destinationViewController as! UINavigationController).viewControllers.first as! ScannerViewController
            addBookController.bookReadState = mode.equivalentBookReadState
        }
    }
    
    /// Gets the specified object from the results controller, casted to a Book
    private func bookAtIndexPath(indexPath: NSIndexPath) -> Book? {
        return booksResultsController.objectAtIndexPath(indexPath) as? Book
    }
    
    /// Configures the text labels on the UICell according to the book at the specified index path
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let book = self.booksResultsController.objectAtIndexPath(indexPath) as! Book
        cell.textLabel!.text = book.title
        cell.detailTextLabel!.text = book.authorListString
    }
}


// Standard fetched results controller delegate code
extension BookTableViewController : NSFetchedResultsControllerDelegate {
    
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
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Update:
                let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
                self.configureCell(cell!, atIndexPath: indexPath!)
                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            }
    }


    /**
     The possible modes in which the BookTableViewController can be used.
    */
    enum BookTableViewMode: Int {
        
        case Reading
        case ToRead
        case Finished
        
        /// A heading and description to use when the book list is empty
        var emptyListTitleAndDescription: (String!, String!){
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
        var title: String!{
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
        var equivalentBookReadState: BookReadState{
            switch self{
            case .Reading:
                return BookReadState.Reading
            case .ToRead:
                return BookReadState.ToRead
            case .Finished:
                return BookReadState.Finished
            }
        }
    }

}

/**
    Functions controlling the DZNEmptyDataSet.
*/
extension BookTableViewController : DZNEmptyDataSetSource{
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