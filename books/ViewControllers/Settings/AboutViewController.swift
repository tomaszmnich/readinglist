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
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableText.hyperlinkText("GitHub", to: URL(string: "https://github.com/AndrewBennet/readinglist")!)
        textView.attributedText = mutableText
    }
}
