//
//  FetchedResultsTable.swift
//  books
//
//  Created by Andrew Bennet on 24/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreData

class FetchedResultsTable: UITableViewController {
    
    /// The controller to get the results to display in this view
    var resultsController: NSFetchedResultsController! {
        didSet {
            // Attach this controller as a delegate on for the results controller, and set the initial predicate
            resultsController.delegate = self
        }
    }
    
    /// The string to use for the cell reuse identifier
    var cellIdentifier: String!
    
    func configureCell(cell: UITableViewCell, fromObject object: AnyObject) {
        // Should be overriden by inheriting classes
    }
    
    override func viewDidLoad() {
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        // Also, we will manage the clearing of selections ourselves. Setting the table footer removes the cell separators
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()
        self.clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView()
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Deselect selected rows, so they don't stay highlighted
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
    }
    
    /// Updates the predicate, performs a fetch and reloads the table view data.
    func updatePredicate(newPredicate: NSPredicate) {
        resultsController.fetchRequest.predicate = newPredicate
        try! resultsController.performFetch()
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.resultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a spare cell, configure the cell for the specified index path and return it
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        configureCell(cell, fromObject: resultsController.objectAtIndexPath(indexPath))
        return cell
    }
}


/**
 The handling of updates from the fetched results controller.
 */
extension FetchedResultsTable: NSFetchedResultsControllerDelegate {
    
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
                cell.configureFromBook(resultsController.objectAtIndexPath(indexPath!) as? Book)
            }
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
}