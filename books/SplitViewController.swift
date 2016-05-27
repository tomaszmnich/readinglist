//
//  SplitViewController.swift
//  books
//
//  Created by Andrew Bennet on 03/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

// This subclass exists solely to stop the app opening in "detail" view on iPhones
class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        self.preferredDisplayMode = .AllVisible
        self.delegate = self
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    var masterNavigationController: UINavigationController {
        return self.viewControllers[0] as! UINavigationController
    }
    
    private var detailNavigationControllerIfSplit: UINavigationController? {
        if self.viewControllers.count >= 2 {
            return self.viewControllers[1] as? UINavigationController
        }
        return nil
    }
    
    /** 
        Clears the detail view - if it is displayed in split view - if the given book
        is currently displayed.
    */
    func clearDetailViewIfBookDisplayedInSplitView(book: Book) {
        if let bookDetails = detailNavigationControllerIfSplit?.viewControllers.first as? BookDetails {
            if bookDetails.book == book {
                bookDetails.ClearUI()
            }
        }
    }
    
    /**
        Clears the detail view - if it is displayed in split view.
    */
    func clearDetailViewIfSplitView() {
        if let bookDetails = detailNavigationControllerIfSplit?.viewControllers.first as? BookDetails {
            bookDetails.ClearUI()
        }
    }
}