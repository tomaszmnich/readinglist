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
    @IBOutlet weak var tab1View: UIView!
    @IBOutlet weak var tab2View: UIView!
    @IBOutlet weak var tab3View: UIView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view of the NavigationController to be white, so that glimpses
        // of dark colours are not seen through the translucent bar when segueing from this view.
        navigationController!.view.backgroundColor = UIColor.white
        tabBar.delegate = self

        setSelectedTab(to: .toRead)
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setSelectedTab(to: TabOption(rawValue: item.tag)!)
    }
    
    @IBAction func addWasPressed(_ sender: AnyObject) {
        func segueAction(title: String, identifier: String) -> UIAlertAction {
            return UIAlertAction(title: title, style: .default){_ in
                self.performSegue(withIdentifier: identifier, sender: sender)
            }
        }
        
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        optionsAlert.addAction(segueAction(title: "Enter Manually", identifier: "addManually"))
        optionsAlert.addAction(segueAction(title: "Search Online", identifier: "searchByText"))
        optionsAlert.addAction(segueAction(title: "Scan Barcode", identifier: "scanBarcode"))
#if DEBUG
        optionsAlert.addAction(UIAlertAction(title: "Add Test Data", style: .default){ _ in
            TestData.loadTestData()
        })
#endif
        
        // For iPad, set the popover presentation controller's source
        if let popPresenter = optionsAlert.popoverPresentationController {
            popPresenter.sourceView = sender.view
            popPresenter.sourceRect = sender.view.bounds
        }
        
        self.present(optionsAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navWithReadState = segue.destination as? NavWithReadState {
            if selectedTabOption == .finished {
                navWithReadState.readState = .finished
            }
            else {
                navWithReadState.readState = .toRead
            }
        }
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        // Check that the user activity corresponds to a book which we have a row for
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let identifierUrl = URL(string: identifier),
            let selectedBook = appDelegate.booksStore.get(bookIdUrl: identifierUrl) else { return }
        
        if selectedBook.readState == .finished {
            setSelectedTab(to: .finished)
            finishedTable.triggerBookSelection(selectedBook)
        }
        else {
            setSelectedTab(to: .toRead)
            readingTable.triggerBookSelection(selectedBook)
        }
    }
    
    private func setSelectedTab(to tabOption: TabOption) {
        tab1View.isHidden = tabOption != .toRead
        tab2View.isHidden = tabOption != .finished
        tab3View.isHidden = tabOption != .settings
        
        switch tabOption {
        case .toRead:
            navigationItem.title = "Reading"
        case .finished:
            navigationItem.title = "Finished"
        default:
            navigationItem.title = "Settings"
            
        }
        
        tabBar.selectedItem = tabBar.items![tabOption.rawValue]
    }
    
    var selectedTabOption: TabOption {
        return TabOption(rawValue: tabBar.selectedItem!.tag)!
    }
    
    var readingTable: ReadingTable {
        return childViewControllers[0] as! ReadingTable
    }
    
    var finishedTable: FinishedTable {
        return childViewControllers[1] as! FinishedTable
    }
}

enum TabOption : Int {
    case toRead = 0
    case finished = 1
    case settings = 2
}
