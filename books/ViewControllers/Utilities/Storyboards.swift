//
//  Storyboards.swift
//  books
//
//  Created by Andrew Bennet on 14/10/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class Storyboard {
    static var SearchOnline: UIStoryboard {
        get { return UIStoryboard(name: "SearchOnline", bundle: Bundle.main) }
    }
    
    static var ScanBarcode: UIStoryboard {
        get { return UIStoryboard(name: "ScanBarcode", bundle: Bundle.main) }
    }
    
    static var AddManually: UIStoryboard {
        get { return UIStoryboard(name: "AddManually", bundle: Bundle.main) }
    }
}

extension UIStoryboard {
    func instantiateRoot() -> UIViewController {
        return self.instantiateInitialViewController()!
    }
}
