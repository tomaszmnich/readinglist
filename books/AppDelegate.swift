 //
//  AppDelegate.swift
//  books
//
//  Created by Andrew Bennet on 09/11/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit
import CoreSpotlight

// Some global variables (naughty)
var appDelegate: AppDelegate {
    return UIApplication.sharedApplication().delegate as! AppDelegate
}
var ReadingTabIndex: Int {
    return 0
}
var ToReadTabIndex: Int{
    return 1
}
var FinishedTabIndex: Int{
    return 2
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var booksStore = BooksStore()
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: [AnyObject]? -> Void) -> Bool {
        
        if userActivity.activityType == CSSearchableItemActionType {
            if let activityIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                print("In restoration handler with identifier: \(activityIdentifier)")
                
                dispatch_async(dispatch_get_main_queue()){
                    let objectUrl = NSURL(string: activityIdentifier)!
                    print("objectUrl is \(objectUrl)")
                    if let book = self.booksStore.GetBook(objectUrl){
                        print("book is \(book)")
                    
                    func tabIndexFromReadState(readState: BookReadState) -> Int{
                        switch readState{
                        case .ToRead: return ToReadTabIndex
                        case.Reading: return ReadingTabIndex
                        case.Finished: return FinishedTabIndex
                        }
                    }
                    
                    print(book.title)
                    
                    /*
                    let relevantTabNavController = (window!.rootViewController as! UITabBarController).viewControllers![tabIndexFromReadState(book.readState)] as! UINavigationController
                    print("got relevant tab nav controller")
                    let tableViewController = relevantTabNavController.viewControllers[0]
                    print("got tableviewcontroller")
                    
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
                    let bookDetailsViewController = mainStoryboard.instantiateViewControllerWithIdentifier("bookDetails") as! BookDetailsViewController
                    bookDetailsViewController.book = book
                    
                    tableViewController.presentViewController(bookDetailsViewController, animated: false, completion: nil)*/
                    
                    }
                }
            }
        }
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

