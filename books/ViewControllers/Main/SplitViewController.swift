//
//  SplitViewController.swift
//  books
//
//  Created by Andrew Bennet on 03/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import SVProgressHUD

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        self.preferredDisplayMode = .allVisible
        self.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    var masterNavigationController: UINavigationController {
        return viewControllers[0] as! UINavigationController
    }
    
    var detailIsPresented: Bool {
        return viewControllers.count >= 2 || masterNavigationController.viewControllers.count >= 2
    }
    
    
    var displayedDetailViewController: UIViewController? {
        // If the master and detail are separate, the detail will be the second item in viewControllers
        if viewControllers.count >= 2,
            let detailNavController = viewControllers[1] as? UINavigationController {
            return detailNavController.viewControllers.first
        }
        
        // Otherwise, navigate to where the Details view controller should be (if it is displayed)
        if masterNavigationController.viewControllers.count >= 2,
            let previewNavController = masterNavigationController.viewControllers[1] as? UINavigationController {
            return previewNavController.viewControllers.first
        }
        
        // The controller is not present
        return nil
    }
}
