//
//  TabbedViewController.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreSpotlight

class TabbedViewController: UIViewController, UITabBarDelegate {

    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var readingTabView: UIView!
    @IBOutlet weak var finishedTabView: UIView!
    @IBOutlet weak var settingsTabView: UIView!
    
    private var addButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view of the NavigationController to be white, so that glimpses of dark 
        // colours are not seen through the translucent bar when segueing from this view.
        navigationController!.view.backgroundColor = UIColor.white
        
        // Construct the bar buttons in the controller, so we can control when they appear.
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWasPressed))
        editButton = editButtonItem
        
        // Set the tab bar delegate to this controller, and always start on tab 1.
        tabBar.delegate = self
        setSelectedTab(to: .toRead)
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
    
    func addWasPressed() {
        func segueAction(title: String, identifier: String) -> UIAlertAction {
            return UIAlertAction(title: title, style: .default){_ in
                self.performSegue(withIdentifier: identifier, sender: self)
            }
        }
        
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.addAction(segueAction(title: "Scan Barcode", identifier: "scanBarcode"))
        optionsAlert.addAction(segueAction(title: "Search Online", identifier: "searchByText"))
        optionsAlert.addAction(segueAction(title: "Enter Manually", identifier: "addManually"))
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad, set the popover presentation controller's source
        if let popPresenter = optionsAlert.popoverPresentationController {
            popPresenter.barButtonItem = addButton
        }

        self.present(optionsAlert, animated: true, completion: nil)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Propagate the editing setting to the selected embedded view controller
        selectedViewController.setEditing(editing, animated: animated)
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
        
        setSelectedTab(to: selectedBook.readState == .finished ? .finished : .toRead)
        (selectedViewController as! BookTable).triggerBookSelection(selectedBook)
    }
    
    private func setSelectedTab(to tabOption: TabOption) {
        // Hide all views except the one which corresponds to the selected tab
        readingTabView.isHidden = tabOption != .toRead
        finishedTabView.isHidden = tabOption != .finished
        settingsTabView.isHidden = tabOption != .settings
        
        // Configure the navigation item
        switch tabOption {
        case .toRead:
            navigationItem.title = "Reading"
            navigationItem.rightBarButtonItem = addButton
            navigationItem.leftBarButtonItem = editButton
        case .finished:
            navigationItem.title = "Finished"
            navigationItem.rightBarButtonItem = addButton
            navigationItem.leftBarButtonItem = editButton
        default:
            navigationItem.title = "Settings"
            navigationItem.rightBarButtonItem = nil
            navigationItem.leftBarButtonItem = nil
        }
        
        // Update the actual tab bar item
        tabBar.selectedItem = tabBar.items![tabOption.rawValue]
        
        // This view controller's editing flag should refelct the selected embedded view controller's flag
        setEditing(selectedViewController.isEditing, animated: false)
    }
}

enum TabOption : Int {
    case toRead = 0
    case finished = 1
    case settings = 2
}
