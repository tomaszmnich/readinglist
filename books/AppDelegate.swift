 //
//  AppDelegate.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreSpotlight

#if DEBUG
    // Include SimulatorStatusMagic only in debug mode; it's only needed for automated screenshots
    import SimulatorStatusMagic
#endif

let productBundleIdentifier = "com.andrewbennet.books"
let appleAppId = "1217139955"
 
var appDelegate: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var booksStore = BooksStore(storeType: .sqlite)
    
    var splitViewController: SplitViewController {
        return window!.rootViewController as! SplitViewController
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        #if DEBUG
            // In debug mode, when we are running via fastlane snapshot, override the simulator status bar
            if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
                SDStatusBarManager.sharedInstance().enableOverrides()
            }
            else {
                SDStatusBarManager.sharedInstance().disableOverrides()
            }
        #endif
        return true
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return userActivityType == CSSearchableItemActionType
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType && userActivity.userInfo?[CSSearchableItemActivityIdentifier] is String {
            splitViewController.tabbedViewController.restoreUserActivityState(userActivity)
            return true
        }
        return false
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "\(productBundleIdentifier).ScanBarcode" {
            splitViewController.tabbedViewController.performSegue(withIdentifier: "scanBarcode", sender: self)
        }
        if shortcutItem.type == "\(productBundleIdentifier).SearchOnline" {
            splitViewController.tabbedViewController.performSegue(withIdentifier: "searchByText", sender: self)
        }
        completionHandler(true)
    }
}

