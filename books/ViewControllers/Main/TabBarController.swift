//
//  TabbedViewController.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreSpotlight

class TabBarController: UITabBarController {
    
    enum TabOption : Int {
        case toRead = 0
        case finished = 1
        case settings = 2
    }
    
    func selectTab(_ tab: TabOption) {
        selectedIndex = tab.rawValue
    }
    
    var selectedSplitViewController: SplitViewController? {
        get { return selectedViewController as? SplitViewController }
    }
    
    func simulateBookSelection(_ book: Book){
        selectTab(book.readState == .finished ? TabOption.finished : TabOption.toRead)
        (selectedSplitViewController?.masterNavigationController.viewControllers.first as? BookTable)?.triggerBookSelection(book)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let identifierUrl = URL(string: identifier),
            let selectedBook = appDelegate.booksStore.get(bookIdUrl: identifierUrl) else { return }
        simulateBookSelection(selectedBook)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let selectedSplitViewController = selectedSplitViewController, item.tag == selectedIndex {
            
            if selectedSplitViewController.masterNavigationController.viewControllers.count > 1 {
               selectedSplitViewController.masterNavigationController.popToRootViewController(animated: true)
            }
            else if let topTable = selectedSplitViewController.masterNavigationController.viewControllers.first as? UITableViewController {
                topTable.tableView.setContentOffset(CGPoint(x: 0, y: 0 - topTable.tableView.contentInset.top), animated: true)
            }
        }
    }
}
