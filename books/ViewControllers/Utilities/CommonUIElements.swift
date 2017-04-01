//
//  CommonUIElements.swift
//  books
//
//  Created by Andrew Bennet on 01/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

func duplicateBookAlertController(addDuplicateHandler: @escaping (Void) -> Void, goToExistingBookHander: @escaping (Void) -> Void, cancelHandler: @escaping (Void) -> Void) -> UIAlertController {
    
    let alert = UIAlertController(title: "Book Already Added", message: "A book with the same ISBN has already been added to your reading list.", preferredStyle: UIAlertControllerStyle.alert)
    
    alert.addAction(UIAlertAction(title: "Add Duplicate", style: UIAlertActionStyle.default){ _ in
        addDuplicateHandler()
    })
    alert.addAction(UIAlertAction(title: "Go To Existing Book", style: UIAlertActionStyle.default){ _ in
        goToExistingBookHander()
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default){ _ in
        cancelHandler()
    })
    return alert
}
