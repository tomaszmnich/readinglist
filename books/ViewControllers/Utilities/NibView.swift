//
//  Nibs.swift
//  books
//
//  Created by Andrew Bennet on 21/10/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class NibView {
    static func withName(_ name: String) -> UIView {
        return UINib(nibName: name, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    static var searchBooksEmptyDataset: SearchBooksEmptyDataset {
        get { return NibView.withName("SearchBooksEmptyDataset") as! SearchBooksEmptyDataset }
    }
}
