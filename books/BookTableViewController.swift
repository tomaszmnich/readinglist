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

@objc protocol BookTableViewControllerDelegate {
    func editViewDidCancel(editController: EditBookViewController)
    func editViewDidSave(editController: EditBookViewController)
}

class BookTableViewController: UITableViewController {
    
    var reloadData = true
    var userReorderingCells = false
    
    // The controller for fetching all books
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true)
        ]
        let moc = appDelegate().coreDataStack.managedObjectContext
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: moc,
            sectionNameKeyPath: nil,
            cacheName: nil)
        controller.delegate = self
        return controller
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload the data
        if presentedViewController != nil{
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        // Set the DZN data set source
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        
        //navigationItem.leftBarButtonItem = editButtonItem()
        super.viewDidLoad()
        
        // Fetch the relevant data
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching: \(error)")
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
        cell.detailTextLabel?.text = book.author
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let book = bookFromIndexPath(indexPath)
            appDelegate().coreDataStack.managedObjectContext.deleteObject(book)
        }
    }
    
    override func tableView(tableView: UITableView,
        moveRowAtIndexPath sourceIndexPath: NSIndexPath,
        toIndexPath destinationIndexPath: NSIndexPath) {
            
            userReorderingCells = true
            
            // Grab the books array
            var books = fetchedResultsController.sections?[0].objects ?? []
            
            // Rearrange the order to match the user's actions
            // Note: this doesn't move anything in Core Data,
            // just our objectsInSection array
            books.moveFrom(sourceIndexPath.row, toDestination: destinationIndexPath.row)
            
            // The models are now in the correct order.
            // Update their displayOrder to match the new order.
            for i in 0..<books.count {
                let book = books[i] as? Book
                book?.sortOrder = Int32(i)
            }
            
            userReorderingCells = false
            appDelegate().coreDataStack.save()
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
        // "addSegue" is for adding a new book
        else if segue.identifier == "addSegue" {
            // Get the EditBook controller
            let editBookController = segue.destinationViewController as! EditBookViewController
            
            // Make a new book in the managed object context, and add it to the controller
            let moc = appDelegate().coreDataStack.managedObjectContext
            let newBook = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: moc) as! Book
            editBookController.book = newBook
            editBookController.creatingNewBook = true
            
            // Set the delegate for callbacks
            editBookController.bookListDelegate = self
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


/*
    Callbacks from the edit view. TODO: do these even need to be callbacks?
*/
extension BookTableViewController: BookTableViewControllerDelegate {
    
    func editViewDidCancel(editController: EditBookViewController) {
        // On cancel, if we have made a new book, delete it. Otherwise, don't save changes.
        if editController.creatingNewBook {
            appDelegate().coreDataStack.managedObjectContext.deleteObject(editController.book)
        }
    }
    
    func editViewDidSave(editController: EditBookViewController) {
        // On save, save the managed object context.
        let _ = try? appDelegate().coreDataStack.managedObjectContext.save()
    }
}



extension BookTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
        guard userReorderingCells == false else { return }
            switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            case .Move:
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            case .Update:
                tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            guard userReorderingCells == false else { return }
        switch type {
            case .Insert:
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
            case .Delete:
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
            default:
                break
            }
    }
}


