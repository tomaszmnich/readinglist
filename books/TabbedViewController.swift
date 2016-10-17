//
//  TabbedViewController.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class TabbedViewController: UIViewController, UITabBarDelegate {

    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var tab1View: UIView!
    @IBOutlet weak var tab2View: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        tabBar.selectedItem = tabBar.items!.first
        tabBar(tabBar, didSelect: tabBar.selectedItem!)
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let selectedTabOption = TabOption(rawValue: item.tag)
        tab1View.isHidden = selectedTabOption != .toRead
        tab2View.isHidden = selectedTabOption != .finished
    }

}

enum TabOption : Int {
    case toRead = 0
    case finished = 1
}
