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
    var resultsController: NSFetchedResultsController<NSFetchRequestResult>! {
        get {
            return nil
        }
    }
    
    /// The string to use for the cell reuse identifier
    var cellIdentifier: String!
    
    func configureCell(_ cell: UITableViewCell, fromObject object: AnyObject) {
        // Should be overriden by inheriting classes
    }
    
    override func viewDidLoad() {
        refetch(reloadTable: true)
        super.viewDidLoad()
    }
    
    /// Enables or disables the fetched results controller delegate
    func toggleUpdates(on: Bool) {
        resultsController.delegate = on ? self : nil
    }
    
    /// Updates the predicate, performs a fetch and reloads the table view data.
    func updatePredicateAndReloadTable(_ newPredicate: NSPredicate) {
        // We shouldn't need to do anything if the predicate is the same, given that we are tracking changes.
        guard resultsController.fetchRequest.predicate != newPredicate else { return }
        
        resultsController.fetchRequest.predicate = newPredicate
        refetch(reloadTable: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.resultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a spare cell, configure the cell for the specified index path and return it
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        configureCell(cell, fromObject: resultsController.object(at: indexPath))
        return cell
    }
    
    func refetch(reloadTable: Bool) {
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
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange object: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            configureCell(tableView.cellForRow(at: indexPath!)!, fromObject: object as AnyObject);
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            // Move and Updates should in theory not occur for sections
            return
        }
    }
}
