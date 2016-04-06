//
//  FetchedResultsTableViewController.swift
//  books
//
//  Created by Andrew Bennet on 30/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit
import CoreData

/**
 A fetched results table generalises some of the table cell updating. Apply the protocol
 on a UITableViewContoller and use the cellForRowAtIndexPath(_) method for the equivalent
 override.
*/
protocol FetchedResultsTable: NSFetchedResultsControllerDelegate{
    associatedtype resultType
    associatedtype cellType
    var resultsController: NSFetchedResultsController {get}
    var tableView: UITableView! {get}
    func configureCell(cell: cellType, fromResult result: resultType)
}

extension FetchedResultsTable {
    func objectAtIndexPath(indexPath: NSIndexPath) -> resultType? {
        return resultsController.objectAtIndexPath(indexPath) as? resultType
    }
    
    func configureCell(cell: cellType, forIndexPath indexPath: NSIndexPath){
        if let result = objectAtIndexPath(indexPath) {
            configureCell(cell, fromResult: result)
        }
    }
    
    func updateCellAt(indexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? cellType {
            configureCell(cell, forIndexPath: indexPath)
        }
    }
    
    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> cellType {
        // Get a spare cell
        let cell = tableView.dequeueReusableCellWithIdentifier(String(cellType), forIndexPath: indexPath) as! cellType
        
        // Configure the cell for the specified index path and return it
        configureCell(cell, forIndexPath: indexPath)
        return cell
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let _ = try? controller.performFetch()
        tableView.reloadData()
        tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .None)
        case .Update:
            updateCellAt(indexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultsController.sections![section].numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cellForRowAtIndexPath(indexPath) as! UITableViewCell
    }

}