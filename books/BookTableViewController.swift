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
    
    let coreDataStack = appDelegate().coreDataStack
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true)
        ]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return controller
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload the data
        tryPerformFetch()
        tableView.reloadData()
    }
    
    func tryPerformFetch(){
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching: \(error)")
        }
    }
    
    override func viewDidLoad() {
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        
        // This removed the cell separators
        tableView.tableFooterView = UIView()
        
        super.viewDidLoad()
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
        cell.detailTextLabel?.text = book.author
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
                bookDetailsController.context = coreDataStack.managedObjectContext
                bookDetailsController.book = clickedBook
            }
        }
        else if segue.identifier == "addSegue"{
            // Get the controller for adding a book
            let addBookController = segue.destinationViewController as! AddBookViewController
            
            // Set the newBookIndex to be one more than the greatest current value
            addBookController.newBookIndex = Int32((fetchedResultsController.sections?[0].objects!.count)!)
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
        let str = "Welcome"
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Tap the button above to add your first book."
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
}