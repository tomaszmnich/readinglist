//
//  TableViewController.swift
//  books
//
//  Created by Andrew Bennet on 13/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreData

/**
 Extends NSFetchedResultsControllerDelegate with methods which return number of rows and sections,
 and can configure a cell for a given IndexPath.
 */
protocol GeneralTableUpdater : NSFetchedResultsControllerDelegate {
    func numberOfSections() -> Int
    func numberOfRows(inSection section: Int) -> Int
    func cellForRow(at indexPath: IndexPath) -> UITableViewCell
    func withoutUpdates(closure: ((Void) -> Void))
}

/**
 A cell which can be configured from a object returned from a NSFetchedResultsController.
*/
protocol ConfigurableCell {
    associatedtype ResultType : NSFetchRequestResult
    func configureFrom(_ result: ResultType)
}

/**
 A generic implementation of TableUpdaterGeneral, typed to the NSFetchedResultsController result type and the UITableViewCell type.
 Given a UITableView, an NSFetchedResultsController and a function to update Cells, can react to changed in the NSFetchedResultsController,
 and also expose the current values for the number of rows and sections, and provide a configured cell for a given IndexPath.
 */
class TableUpdater<ResultType, CellType> : NSObject, GeneralTableUpdater
where ResultType : NSFetchRequestResult, CellType : UITableViewCell, CellType: ConfigurableCell, CellType.ResultType == ResultType {
    
    private let tableView: UITableView
    private let controller: NSFetchedResultsController<ResultType>
    private let cellIdentifier = String(describing: CellType.self)
    
    init(table: UITableView, controller: NSFetchedResultsController<ResultType>){
        self.tableView = table
        self.controller = controller
        super.init()
        
        self.controller.delegate = self
    }
    
    func numberOfSections() -> Int {
        return controller.sections?.count ?? 0
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        return controller.sections?[section].numberOfObjects ?? 0
    }
    
    func cellForRow(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CellType
        cell.configureFrom(controller.object(at: indexPath))
        return cell
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange object: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? CellType, let result = object as? ResultType {
                cell.configureFrom(result)
            }
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
    
    func withoutUpdates(closure: ((Void) -> Void)) {
        tableView.delegate = nil
        closure()
        controller.delegate = self
    }
}

/**
 A UITableViewController which automatically updates its cells via a TableUpdaterGeneral object,
 provided the tableUpdater variable is assigned on load.
 */
class AutoUpdatingTableViewController : UITableViewController {
    var tableUpdater: GeneralTableUpdater!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableUpdater.numberOfRows(inSection: section)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableUpdater.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableUpdater.cellForRow(at: indexPath)
    }
}
