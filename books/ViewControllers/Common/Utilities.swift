//
//  NavigationControllerWithReadState.swift
//  books
//
//  Created by Andrew Bennet on 01/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import Eureka

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

func NavigationRow(title: String, segueName: String, initialiser: ((ButtonRow) -> Void)? = nil, updater: ((ButtonCellOf<String>, ButtonRow) -> Void)? = nil) -> ButtonRow {
    return ButtonRow() {
        $0.title = title
        $0.presentationMode = .segueName(segueName: segueName, onDismiss: nil)
        initialiser?($0)
        }.cellUpdate{ cell, row in
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.textColor = .black
            cell.accessoryType = .disclosureIndicator
            updater?(cell, row)
    }
}

func ActionButton(title: String, updater: ((ButtonCellOf<String>, ButtonRow) -> Void)? = nil, action: @escaping () -> Void) -> ButtonRow {
    return ButtonRow() {
        $0.title = title
        }.cellUpdate{ cell, row in
            cell.textLabel?.textAlignment = .left
            updater?(cell, row)
        }.onCellSelection{_,_ in
            action()
    }
}
