//
//  ReadingTable.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class ReadingTable: BookTable {

    override func viewDidLoad() {
        readStates = [.toRead, .reading]
        super.viewDidLoad()
    }
    
    var toReadSectionIndex: Int? {
        get {
            if let toReadSectionIndex = resultsController.sections?.index(where: {$0.name == String.init(describing: BookReadState.toRead.rawValue)}) {
                return resultsController.sections!.startIndex.distance(to: toReadSectionIndex)
            }
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // We can reorder the "ToRead" books if there are more than one
            return indexPath.section == toReadSectionIndex &&
                self.tableView(tableView, numberOfRowsInSection: toReadSectionIndex!) > 1
    }
    
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        else {
            return IndexPath(row: 0, section: toReadSectionIndex!)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // We should only have movement in the ToRead secion. We also ignore moves which have no effect
        guard let toReadSectionIndex = toReadSectionIndex else { return }
        guard sourceIndexPath.section == toReadSectionIndex && destinationIndexPath.section == toReadSectionIndex else { return }
        guard sourceIndexPath.row != destinationIndexPath.row else { return }
        
        // Calculate the ordering of the two rows involved
        let itemMovedDown = sourceIndexPath.row < destinationIndexPath.row
        let firstRow = itemMovedDown ? sourceIndexPath.row : destinationIndexPath.row
        let lastRow = itemMovedDown ? destinationIndexPath.row : sourceIndexPath.row
        
        // Move the objects to reflect the rows
        var objectsInSection = resultsController.sections![toReadSectionIndex].objects!
        let movedObj = objectsInSection.remove(at: sourceIndexPath.row)
        objectsInSection.insert(movedObj, at: destinationIndexPath.row)
        
        // Update the model to reflect the objects's positions
        #if DEBUG
            print("**** Reordering Rows ****")
        #endif
        for rowNumber in firstRow...lastRow {
            let book = objectsInSection[rowNumber] as! Book
            book.sort = rowNumber as NSNumber?
            #if DEBUG
            print("\(book.title) set to Sort: \(book.sort!)")
            #endif
        }
        #if DEBUG
            print("**** Finished Reordering Rows ****")
            print("")
        #endif
        
        // Turn off updates while we save the object context
        tableUpdater.withoutUpdates {
            appDelegate.booksStore.save()
            try? resultsController.performFetch()
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return rowActionsForBookInState(indexPath.section == toReadSectionIndex ? .toRead : .reading)
    }
}
