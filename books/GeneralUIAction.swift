//
//  Helpers.swift
//  books
//
//  Created by Andrew Bennet on 09/03/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

/// An abstraction of the commonalities of UITableViewRowAction and UIPreviewAction.
/// Provided that one can map from the inputs of the action callback (e.g. IndexPath, UIPreviewAction, etc)
/// to some ActionableObject, then the function to be performed on the actionable object can be shared in this class.
class GeneralUIAction<ActionableObject> {
    
    let title: String
    let style: GeneralUIActionStyle
    let action: ((ActionableObject) -> Void)
    
    init(style: GeneralUIActionStyle, title: String, action: @escaping ((ActionableObject) -> Void)){
        self.style = style
        self.title = title
        self.action = action
    }
    
    func toUIPreviewAction(getActionableObject: @escaping (UIPreviewAction, UIViewController) -> ActionableObject) -> UIPreviewAction {
        return UIPreviewAction(title: self.title, style: self.style.toUIPreviewActionItemStyle()){
            let actionableObject = getActionableObject($0, $1)
            self.action(actionableObject)
        }
    }
    
    func toUITableViewRowAction(getActionableObject: @escaping (UITableViewRowAction, IndexPath) -> ActionableObject) -> UITableViewRowAction {
        return UITableViewRowAction(style: self.style.toUITableViewRowActionStyle(), title: self.title) {
            let actionableObject = getActionableObject($0, $1)
            self.action(actionableObject)
        }
    }
}


enum GeneralUIActionStyle {
    case normal
    case destructive
    
    func toUITableViewRowActionStyle() -> UITableViewRowActionStyle {
        switch self{
        case .normal:
            return .normal
        case .destructive:
            return .destructive
        }
    }
    
    func toUIPreviewActionItemStyle() -> UIPreviewActionStyle {
        switch self {
        case .normal:
            return .default
        case .destructive:
            return .destructive
        }
    }
}
