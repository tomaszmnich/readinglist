//
//  CommonUIElements.swift
//  books
//
//  Created by Andrew Bennet on 01/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

func duplicateBookAlertController(goToExistingBook: @escaping () -> (), cancel: @escaping () -> ()) -> UIAlertController {
    
    let alert = UIAlertController(title: "Book Already Added", message: "A book with the same ISBN or Google Books ID has already been added to your reading list.", preferredStyle: UIAlertControllerStyle.alert)

    // "Go To Existing Book" option - dismiss the provided ViewController (if there is one), and then simulate the book selection
    alert.addAction(UIAlertAction(title: "Go To Existing Book", style: UIAlertActionStyle.default){ _ in
        goToExistingBook()
    })
    
    // "Cancel" should just envoke the callback
    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel){ _ in
        cancel()
    })
    
    return alert
}
