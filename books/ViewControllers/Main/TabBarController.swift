//
//  TabbedViewController.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreSpotlight
import Eureka

class TabBarController: UITabBarController {
    
    enum TabOption : Int {
        case toRead = 0
        case finished = 1
        case settings = 2
    }
    
    func selectTab(_ tab: TabOption) {
        selectedIndex = tab.rawValue
    }
    
    func selectTab(forState state: BookReadState) -> BookTable {
        selectTab(state == .finished ? .finished : .toRead)
        return selectedBookTable!
    }
    
    var selectedTab: TabOption {
        get { return TabOption(rawValue: selectedIndex)! }
    }
    
    var selectedReadState: BookReadState {
        get { return selectedTab == .finished ? .finished : .toRead }
    }
    
    var selectedSplitViewController: SplitViewController? {
        get { return selectedViewController as? SplitViewController }
    }

    var selectedBookTable: BookTable? {
        get { return (selectedSplitViewController?.masterNavigationController.viewControllers.first as? BookTable) }
    }
    
    func simulateBookSelection(_ book: Book, allowTableObscuring: Bool) {
        selectTab(forState: book.readState).simulateBookSelection(book, allowTableObscuring: allowTableObscuring)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let identifierUrl = URL(string: identifier),
            let selectedBook = appDelegate.booksStore.get(bookIdUrl: identifierUrl) else { return }
        
        // Dismiss any modally presented VCs (edit book, etc).
        presentedViewController?.dismiss(animated: false)

        simulateBookSelection(selectedBook, allowTableObscuring: true)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let selectedSplitViewController = selectedSplitViewController, item.tag == selectedIndex {
            
            if selectedSplitViewController.masterNavigationController.viewControllers.count > 1 {
               selectedSplitViewController.masterNavigationController.popToRootViewController(animated: true)
            }
            else if let topVc = selectedSplitViewController.masterNavigationController.viewControllers.first,
                let topTable = (topVc as? UITableViewController)?.tableView ?? (topVc as? FormViewController)?.tableView,
                topTable.numberOfSections > 0, topTable.contentOffset.y > 0 {
                    topTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
}
