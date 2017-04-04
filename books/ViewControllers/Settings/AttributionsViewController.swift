//
//  AttributionsViewController].swift
//  books
//
//  Created by Andrew Bennet on 12/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class AttributionsViewController : UIViewController {
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableText.hyperlinkText("Icons8", to: URL(string: "https://icons8.com")!)
        mutableText.hyperlinkText("Eureka", to: URL(string: "https://github.com/xmartlabs/Eureka")!)
        mutableText.hyperlinkText("ImageRow", to: URL(string: "https://github.com/EurekaCommunity/ImageRow/")!)
        mutableText.hyperlinkText("DZNEmptyDataSet", to: URL(string: "https://github.com/dzenbot/DZNEmptyDataSet")!)
        mutableText.hyperlinkText("SwiftyJSON", to: URL(string: "https://github.com/SwiftyJSON/SwiftyJSON")!)
        mutableText.hyperlinkText("RxSwift", to: URL(string: "https://github.com/ReactiveX/RxSwift")!)
        mutableText.hyperlinkText("SVProgressHUD", to: URL(string: "https://github.com/SVProgressHUD/SVProgressHUD")!)
        mutableText.hyperlinkText("RxSwiftUtilities", to: URL(string: "https://github.com/RxSwiftCommunity/RxSwiftUtilities")!)
        mutableText.hyperlinkText("CSVImporter", to: URL(string: "https://github.com/Flinesoft/CSVImporter")!)
        mutableText.hyperlinkText("HandySwift", to: URL(string: "https://github.com/Flinesoft/HandySwift")!)
        
        textView.attributedText = mutableText
    }
}
