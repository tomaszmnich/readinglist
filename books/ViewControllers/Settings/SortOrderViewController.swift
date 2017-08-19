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
            
            let info = TableSortOrderInfo.Options[tableSort]!
            return ListCheckRow<TableSortOrder>() {
                $0.title = info.displayName
                $0.selectableValue = info.sortOrder
                $0.value = UserSettings.tableSortOrder == info.sortOrder ? info.sortOrder : nil
            }
        }
        
        form +++ SelectableSection<ListCheckRow<TableSortOrder>>(header: "Order", footer: "Choose the sort order to be used when displaying your books:\n\n • By Date: orders books you are currently reading by start date; books you have finished by finish date. The order of books in the To Read state is customisable - tap Edit and drag to reorder the books.\n\n • By Title: orders all books by title\n\n • By Author: orders all books by the first author's surname", selectionType: .singleSelection(enableDeselection: false))
        
        
            <<< tableSortRow(.byDate)
            <<< tableSortRow(.byTitle)
            <<< tableSortRow(.byAuthor)
    }
    
    override func valueHasBeenChanged(for row: BaseRow, oldValue: Any?, newValue: Any?) {
        guard row.section === form[0] else { return }
        guard let selectedSort = (row.section as! SelectableSection<ListCheckRow<TableSortOrder>>).selectedRow()?.baseValue as? TableSortOrder else { return }
        
        UserSettings.tableSortOrder = selectedSort
    }
}

enum TableSortOrder: Int {
    // 0 is the default preference value.
    case byDate = 0
    case byTitle = 1
    case byAuthor = 2
}

struct TableSortOrderInfo {
    let sortOrder: TableSortOrder
    let displayName: String
    
    private init(sortOrder: TableSortOrder, displayName: String) {
        self.sortOrder = sortOrder
        self.displayName = displayName
    }
    
    static let Options: [TableSortOrder: TableSortOrderInfo] =
        [.byDate: TableSortOrderInfo(sortOrder: .byDate, displayName: "By Date"),
        .byTitle: TableSortOrderInfo(sortOrder: .byTitle, displayName: "By Title"),
        .byAuthor: TableSortOrderInfo(sortOrder: .byAuthor, displayName: "By Author")]
}

class UserSettings {
    
    private static let tableSortOrderKey = "tableSortOrder"
    static var tableSortOrder: TableSortOrder {
        get {
            return TableSortOrder(rawValue: UserDefaults.standard.integer(forKey: tableSortOrderKey)) ?? .byDate
        }
        set {
            if newValue != tableSortOrder {
                UserDefaults.standard.set(newValue.rawValue, forKey: tableSortOrderKey)
                NotificationCenter.default.post(name: Notification.Name.onBookSortOrderChanged, object: nil)
            }
        }
    }
    
    static var selectedSortOrder: [NSSortDescriptor] {
        get { return SortOrders[UserSettings.tableSortOrder]! }
    }
    
    private static let SortOrders = [TableSortOrder.byDate: [BookPredicate.readStateSort,
                                                            BookPredicate.sortIndexSort,
                                                            BookPredicate.finishedReadingDescendingSort,
                                                            BookPredicate.startedReadingDescendingSort],
                                    TableSortOrder.byTitle: [BookPredicate.readStateSort,
                                                             BookPredicate.titleSort],
                                    TableSortOrder.byAuthor: [BookPredicate.readStateSort,
                                                              BookPredicate.authorSort]
                                    ]
}

extension Notification.Name {
    static let onBookSortOrderChanged = Notification.Name("on-book-sort-order-changed")
}
