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
    
    var bookTableController: BookTable {
        return masterNavigationController.viewControllers[0] as! BookTable
    }
    
    var detailNavigationControllerIfSplit: UINavigationController? {
        return self.viewControllers[safe: 1] as? UINavigationController
    }
    
    var detailNavigationController: UINavigationController? {
        return detailNavigationControllerIfSplit ?? masterNavigationController.topViewController as? UINavigationController
    }
    
    var bookDetailsControllerIfSplit: BookDetails? {
        return detailNavigationControllerIfSplit?.viewControllers.first as? BookDetails
    }
}