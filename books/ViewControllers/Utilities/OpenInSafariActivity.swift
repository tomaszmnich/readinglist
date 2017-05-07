//
//  OpenInSafariActivity.swift
//  books
//
//  Created by Andrew Bennet on 07/05/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//
/*

import Foundation
import UIKit

class OpenInSafariActivity: UIActivity {
    override var activityImage: UIImage? {
        get {
            // obviously stupid
            return #imageLiteral(resourceName: "PoweredByGoogle")
        }
    }
    
    override var activityTitle: String? {
        get {
            return "Open in Safari"
        }
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for activityItem in activityItems
        {
            if let url = activityItem as? URL, UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    var url: URL?
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for activityItem in activityItems
        {
            if let url = activityItem as? URL, UIApplication.shared.canOpenURL(url) {
                self.url = url
                break
            }
        }
    }
    
    override func perform() {
        var completed = false
        if let url = self.url
        {
            completed = UIApplication.shared.openURL(url)
        }
        
        self.activityDidFinish(completed)
    }
}
*/
