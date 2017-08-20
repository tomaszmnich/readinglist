//
//  SortOrderViewController.swift
//  books
//
//  Created by Andrew Bennet on 08/08/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka

class SortOrderViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func tableSortRow(_ tableSort: TableSortOrder) -> ListCheckRow<TableSortOrder> {
            return ListCheckRow<TableSortOrder>() {
                $0.title = tableSort.displayName
                $0.selectableValue = tableSort
                $0.value = UserSettings.tableSortOrder == tableSort ? tableSort : nil
            }
        }
        
        form +++ SelectableSection<ListCheckRow<TableSortOrder>>(header: "Order", footer: "Choose the sort order to be used when displaying your books:\n\n • By Date: orders books you are currently reading by start date; books you have finished by finish date. The order of books in the To Read state is customisable - tap Edit and drag to reorder the books.\n\n • By Title: orders all books by title", selectionType: .singleSelection(enableDeselection: false))
        
        
            <<< tableSortRow(.byDate)
            <<< tableSortRow(.byTitle)
    }
    
    override func valueHasBeenChanged(for row: BaseRow, oldValue: Any?, newValue: Any?) {
        guard row.section === form[0] else { return }
        guard let selectedSort = (row.section as! SelectableSection<ListCheckRow<TableSortOrder>>).selectedRow()?.baseValue as? TableSortOrder else { return }
        
        UserSettings.tableSortOrder = selectedSort
    }
}
