//
//  NavigationControllerWithReadState.swift
//  books
//
//  Created by Andrew Bennet on 01/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit

class NavWithReadState: UINavigationController {
    var readState: BookReadState!
}

class PreviewingNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        return self.topViewController!.previewActionItems
    }
}


class HairlineConstraint: NSLayoutConstraint {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.constant = 1.0 / UIScreen.main.scale
    }
}

class BorderedButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Style the button
        layer.cornerRadius = 4
        layer.borderWidth = 1
        setColor(tintColor)
    }
    
    func setColor(_ colour: UIColor) {
        tintColor = colour
        layer.borderColor = colour.cgColor
    }
}

extension UIBarButtonItem {
    func toggleHidden(hidden: Bool) {
        isEnabled = !hidden
        tintColor = hidden ? UIColor.clear : nil
    }
}
