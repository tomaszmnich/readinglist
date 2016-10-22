//
//  ReadingTable.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class ReadingTable: BookTable {

    override func viewDidLoad() {
        readStates = [.toRead, .reading]
        super.viewDidLoad()
        
        //tableView.allowsSelectionDuringEditing = true
    }
    
    /*
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }*/

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // We can reorder the "ToRead" books, if there are more than one
        return indexPath.section == 1 && self.tableView(tableView, numberOfRowsInSection: 1) > 1
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        else {
            return IndexPath(row: 0, section: 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // We should only have movement in section 1. We also ignore moves which have no effect
        guard sourceIndexPath.section == 1 && destinationIndexPath.section == 1 else { return }
        guard sourceIndexPath.row != destinationIndexPath.row else { return }
        
        // Calculate the ordering of the two rows involved
        let itemMovedDown = sourceIndexPath.row < destinationIndexPath.row
        let firstRow = itemMovedDown ? sourceIndexPath.row : destinationIndexPath.row
        let lastRow = itemMovedDown ? destinationIndexPath.row : sourceIndexPath.row
        
        // Move the objects to reflect the rows
        var objectsInSection = resultsController.sections![1].objects!
        let movedObj = objectsInSection.remove(at: sourceIndexPath.row)
        objectsInSection.insert(movedObj, at: destinationIndexPath.row)
        
        // Update the model to reflect the objects's positions
        for rowNumber in firstRow...lastRow {
            (objectsInSection[rowNumber] as! Book).sort = rowNumber as NSNumber?
        }
        
        // Turn off updates while we save the object context
        tableUpdater.withoutUpdates {
            appDelegate.booksStore.save()
            try! resultsController.performFetch()
        }
    }

}
