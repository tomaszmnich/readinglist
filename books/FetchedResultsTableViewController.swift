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
/*
class FetchedResultsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // Standard fetched results controller delegate code
        
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
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .None)
            case .Update:
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath!){
                    self.configureCell(cell as! BookTableViewCell, atIndexPath: indexPath!)
                    self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                }
            case .Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
            }
        }
}*/