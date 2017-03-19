//
//  AboutViewController.swift
//  books
//
//  Created by Andrew Bennet on 12/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class AboutViewController : UIViewController {
    
    @IBOutlet weak var appSourceText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mutableText = NSMutableAttributedString(attributedString: appSourceText.attributedText!)
        mutableText.hyperlinkText("GitHub", to: URL(string: "https://github.com/AndrewBennet/readinglist")!)
        appSourceText.attributedText = mutableText
        appSourceText.textContainerInset = UIEdgeInsets.zero
        appSourceText.textContainer.lineFragmentPadding = 0
    }
}
