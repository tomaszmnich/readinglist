//
//  UserEngagement.swift
//  books
//
//  Created by Andrew Bennet on 28/07/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import StoreKit
import Crashlytics

class UserEngagement {
    static let appStartupCountKey = "appStartupCount"
    static let userEngagementCountKey = "userEngagementCount"
    
    static func onReviewTrigger() {
        PersistedCounter.incrementCounter(withKey: userEngagementCountKey)
        if #available(iOS 10.3, *), shouldTryRequestReview() {
            SKStoreReviewController.requestReview()
        }
    }
    
    static func onAppOpen() {
        PersistedCounter.incrementCounter(withKey: appStartupCountKey)
    }
    
    enum Event: String {
        case searchOnline = "Search Online"
        case scanBarcode = "Scan Barcode"
        case addManualBook = "Add Manual Book"
        case csvImport = "CSV Import"
        case csvExport = "CSV Export"
        case transitionReadState = "Transition Read State"
        case deleteBook = "Delete Book"
        case editBook = "Edit Book"
        case editReadState = "Edit Read State"
        case searchOnlineQuickAction = "Quick Action Search Online"
        case scanBarcodeQuickAction = "Quick Action Scan Barcode"
    }
    
    static func logEvent(_ event: Event) {
        Answers.logCustomEvent(withName: event.rawValue, customAttributes: [:])
    }
    
    private static func shouldTryRequestReview() -> Bool {
        let appStartCountMinRequirement = 2
        let userEngagementModulo = 10
        
        let appStartCount = PersistedCounter.getCount(withKey: appStartupCountKey)
        let userEngagementCount = PersistedCounter.getCount(withKey: userEngagementCountKey)
        
        return appStartCount >= appStartCountMinRequirement && userEngagementCount % userEngagementModulo == 0
    }
}

class PersistedCounter {
    static func incrementCounter(withKey key: String) {
        let newCount = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(newCount, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    static func getCount(withKey: String) -> Int {
        return UserDefaults.standard.integer(forKey: withKey)
    }
}

public extension UIDevice {
    
    // From https://stackoverflow.com/a/26962452/5513562
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
