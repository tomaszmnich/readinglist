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
}