//
//  UserSettings.swift
//  books
//
//  Created by Andrew Bennet on 20/08/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation

enum TableSortOrder: Int {
    // 0 is the default preference value.
    case byDate = 0
    case byTitle = 1
    
    var displayName: String {
        switch self {
        case .byDate:
            return "By Date"
        case .byTitle:
            return "By Title"
        }
    }
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
                                                              BookPredicate.titleSort]]
}

extension Notification.Name {
    static let onBookSortOrderChanged = Notification.Name("on-book-sort-order-changed")
}
