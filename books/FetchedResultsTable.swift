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
        refetch(reloadTable: true)
        super.viewDidLoad()
    }
    
    /// Enables or disables the fetched results controller delegate
    func toggleUpdates(on on: Bool) {
        resultsController.delegate = on ? self : nil
    }
    
    /// Updates the predicate, performs a fetch and reloads the table view data.
    func updatePredicateAndReloadTable(newPredicate: NSPredicate) {
        // We shouldn't need to do anything if the predicate is the same, given that we are tracking changes.
        guard resultsController.fetchRequest.predicate != newPredicate else { return }
        
        resultsController.fetchRequest.predicate = newPredicate
        refetch(reloadTable: true)
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
    
    func refetch(reloadTable reloadTable: Bool) {
        do {
            try resultsController.performFetch()
            if reloadTable {
                tableView.reloadData()
            }
        }
        catch {
            print("Error performing fetch: \(error)")
        }
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
        switch type {
        case .Update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, fromObject: object);
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Move:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, fromObject: object);
            // For some weird reason, updates sometimes get notified as a move from
            // and to the same index path. Don't bother moving the cell in this case.
            if indexPath != newIndexPath {
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
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