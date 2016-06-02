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
        
        refetchAndReloadTable()
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Deselect selected rows, so they don't stay highlighted
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: animated)
        }
    }
    
    /// Updates the predicate, performs a fetch and reloads the table view data.
    func updatePredicateAndReloadTable(newPredicate: NSPredicate) {
        if resultsController.fetchRequest.predicate != newPredicate {
            resultsController.fetchRequest.predicate = newPredicate
            refetchAndReloadTable()
        }
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
    
    func refetchAndReloadTable() {
        debugPrint("resultsController performing fetch with predicate: \(resultsController.fetchRequest.predicate)")
        let _ = try? resultsController.performFetch()
        tableView.reloadData()
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
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        debugPrint("controller delegate received \(type) change notification.")
        switch type {
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Move:
            // For some weird reason, updates sometimes get notified as a move from
            // and to the same index path. Handle this nicely.
            if indexPath == newIndexPath {
                tableView.reloadRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            }
            else {
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            }
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default:
            // Move and Updates should in theory not occur for sections
            return
        }
    }
}