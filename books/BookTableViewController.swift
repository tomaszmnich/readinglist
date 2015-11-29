//
//  BookTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import DZNEmptyDataSet
import CoreData

class BookTableViewController: UITableViewController {
    
    /// The mode in which this BookTableViewController is operating.
    var mode: BookTableViewMode!
    
    /// The possible modes in which the BookTableViewController can be used.
    enum BookTableViewMode: Int{

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
        var equivalentBookReadState: Int32{
            switch self{
            case .Reading:
                return BookReadState.Reading.rawValue
            case .ToRead:
                return BookReadState.ToRead.rawValue
            case .Finished:
                return BookReadState.Finished.rawValue
            }
        }
    }
    
    let coreDataStack = appDelegate().coreDataStack
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "readState == \(self.mode.equivalentBookReadState)")
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return controller
    }()

    override func viewWillAppear(animated: Bool){
        print("BookTableViewController in \"\(mode.title)\" mode will appear.")
        
        // Reload the data
        tryPerformFetch()
        tableView.reloadData()
        
        super.viewWillAppear(animated)
    }
    
    private func tryPerformFetch(){
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching: \(error)")
        }
    }
    
    override func viewDidLoad() {
        // Set the mode variable
        setMode()
        
        // Set the title accordinly
        self.navigationItem.title = mode.title
        
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // This removes the cell separators
        tableView.tableFooterView = UIView()
        
        super.viewDidLoad()
    }
    
    /// Sets the mode variable based on the currently selected tab.
    private func setMode() {
        print("Current tab: \(self.tabBarController!.selectedIndex)")
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
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        // Configure the cell from the corresponding book
        let book: Book = bookFromIndexPath(indexPath)
        cell.textLabel?.text = book.title
        cell.detailTextLabel?.text = book.authorListString
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // "detailsSegue" is for viewing a specific book
        if segue.identifier == "detailsSegue" {
            if let clickedCell = sender as? UITableViewCell {
                // Get the controller for viewing a book
                let bookDetailsController = segue.destinationViewController as! BookDetailsViewController

                // Get the index path of the clicked cell
                let clickedBook = bookFromIndexPath(tableView.indexPathForCell(clickedCell)!)

                // Set the book on the controller from the book corresponding to the clicked cell
                bookDetailsController.book = clickedBook
            }
        }
    }
    
    /*
        Gets the book corresponding to a specific index path in the table.
    */
    func bookFromIndexPath(indexPath: NSIndexPath) -> Book {
        return fetchedResultsController.objectAtIndexPath(indexPath) as! Book
    }
}

/*
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