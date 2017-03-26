//
//  TabbedViewController.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreSpotlight

protocol NavBarChangedDelegate {
    func navBarChanged()
}

protocol NavBarConfigurer: class {
    func configureNavBar(_ navBar: UINavigationItem)
    var navBarChangedDelegate: NavBarChangedDelegate! {get set}
}

class TabbedViewController: UIViewController, UITabBarDelegate, NavBarChangedDelegate {

    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var readingTabView: UIView!
    @IBOutlet weak var finishedTabView: UIView!
    @IBOutlet weak var settingsTabView: UIView!
    
    private var editButton: UIBarButtonItem!
    
    enum TabOption : Int {
        case toRead = 0
        case finished = 1
        case settings = 2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view of the NavigationController to be white, so that glimpses of dark 
        // colours are not seen through the translucent bar when segueing from this view.
        navigationController!.view.backgroundColor = UIColor.white
        
        // Set the tab bar delegate to this controller, and always start on tab 1.
        tabBar.delegate = self
        setSelectedTab(to: .toRead)
        
        // All the child controllers should be NavBarConfigurers
        for childController in childViewControllers {
            (childController as! NavBarConfigurer).navBarChangedDelegate = self
        }
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setSelectedTab(to: TabOption(rawValue: item.tag)!)
    }
    
    var selectedTabOption: TabOption {
        return TabOption(rawValue: tabBar.selectedItem!.tag)!
    }
    
    var selectedViewController: UIViewController {
        return childViewControllers[selectedTabOption.rawValue]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navWithReadState = segue.destination as? NavWithReadState {
            navWithReadState.readState = selectedTabOption == .finished ? .finished : .toRead
        }
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let identifierUrl = URL(string: identifier),
            let selectedBook = appDelegate.booksStore.get(bookIdUrl: identifierUrl) else { return }
        simulateBookSelection(selectedBook)
    }
    
    func simulateBookSelection(_ book: Book){
        setSelectedTab(to: book.readState == .finished ? .finished : .toRead)
        (selectedViewController as! BookTable).triggerBookSelection(book)
    }
    
    func navBarChanged() {
        (selectedViewController as? NavBarConfigurer)?.configureNavBar(navigationItem)
    }
    
    func setSelectedTab(to tabOption: TabOption) {
        // Update the actual tab bar item. This line should remain first, so that selectedViewController is updated
        tabBar.selectedItem = tabBar.items![tabOption.rawValue]
        
        // Hide all views except the one which corresponds to the selected tab
        readingTabView.isHidden = tabOption != .toRead
        finishedTabView.isHidden = tabOption != .finished
        settingsTabView.isHidden = tabOption != .settings
        
        navBarChanged()
    }
}
