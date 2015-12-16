//
//  TabBarController.swift
//  books
//
//  Created by Andrew Bennet on 08/12/2015.
//  Copyright © 2015 Andrew Bennet. All rights reserved.
//

import UIKit

class UIViewControllerWithContext : UIViewController {
    var bookStore: BooksStore!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        segue.destinationViewController
    }
}

class TabBarController : UITabBarController{
    var bookStore: BooksStore!
    
    
}