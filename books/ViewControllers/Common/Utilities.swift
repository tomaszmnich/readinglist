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

@IBDesignable
class BorderedButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 12
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 0
        setTitleColor(UIColor.white, for: state)
        setColor(tintColor)
    }
    
    func setColor(_ colour: UIColor) {
        backgroundColor = colour
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        awakeFromNib()
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

func ActionButton(title: String, action: @escaping () -> Void, updater: ((ButtonCellOf<String>, ButtonRow) -> Void)? = nil) -> ButtonRow {
    return ButtonRow() {
        $0.title = title
        }.cellUpdate{ cell, row in
            cell.textLabel?.textAlignment = .left
            updater?(cell, row)
        }.onCellSelection{_,_ in
            action()
    }
}

func ActionButton(title: String, updater: ((ButtonCellOf<String>, ButtonRow) -> Void)? = nil, url: URL) -> ButtonRow {
    return ActionButton(title: title, action: {UIApplication.shared.openUrlPlatformSpecific(url: url)}, updater: updater)
}

/**
 Wraps an instance of UINotificationFeedbackGenerator (if running on iOS >= 10), so that
 a reference can be held on a VC which supports iOS < 10.
 */
class UIFeedbackGeneratorWrapper {
    private let _notificationGenerator: NSObject?

    @available(iOS 10.0, *)
    var generator: UINotificationFeedbackGenerator {
        get {
            return _notificationGenerator as! UINotificationFeedbackGenerator
        }
    }

    init() {
        if #available(iOS 10.0, *) {
            _notificationGenerator = UINotificationFeedbackGenerator()
        }
        else {
            _notificationGenerator = nil
        }
    }
}
