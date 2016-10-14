//
//  SplitViewController.swift
//  books
//
//  Created by Andrew Bennet on 03/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

// This subclass stops the app opening in "detail" view on iPhones
class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        self.preferredDisplayMode = .allVisible
        self.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    var masterNavigationController: UINavigationController {
        return self.viewControllers[0] as! UINavigationController
    }
    
    var bookTableController: BookTable {
        return masterNavigationController.viewControllers[0] as! BookTable
    }
    
    var detailNavigationControllerIfSplit: UINavigationController? {
        if self.viewControllers.count >= 2 {
            return self.viewControllers[1] as? UINavigationController
        }
        return nil
    }
    
    var detailNavigationController: UINavigationController? {
        return detailNavigationControllerIfSplit ?? masterNavigationController.topViewController as? UINavigationController
    }
    
    var bookDetailsControllerIfSplit: BookDetails? {
        return detailNavigationControllerIfSplit?.viewControllers.first as? BookDetails
    }
}
