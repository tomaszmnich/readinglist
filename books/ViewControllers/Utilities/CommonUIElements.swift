//
//  CommonUIElements.swift
//  books
//
//  Created by Andrew Bennet on 01/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

func duplicateBookAlertController(_ book: Book, modalControllerToDismiss: UIViewController? = nil, cancel: @escaping (Void) -> Void) -> UIAlertController {
    
    let alert = UIAlertController(title: "Book Already Added", message: "A book with the same ISBN has already been added to your reading list.", preferredStyle: UIAlertControllerStyle.alert)

    // "Go To Existing Book" option - dismiss the provided ViewController (if there is one), and then simulate the book selection
    alert.addAction(UIAlertAction(title: "Go To Existing Book", style: UIAlertActionStyle.default){ _ in
        if let modalControllerToDismiss = modalControllerToDismiss {
            modalControllerToDismiss.dismiss(animated: true) {
                appDelegate.splitViewController.tabbedViewController.simulateBookSelection(book)
            }
        }
        else {
            appDelegate.splitViewController.tabbedViewController.simulateBookSelection(book)
        }
    })
    
    // "Cancel" should just envoke the callback
    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel){ _ in
        cancel()
    })
    
    return alert
}
