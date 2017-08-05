//
//  UserEngagement.swift
//  books
//
//  Created by Andrew Bennet on 28/07/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import StoreKit
import Fabric
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
    }
    
    static func logEvent(_ event: Event) {
        Answers.logCustomEvent(withName: event.rawValue, customAttributes: [:])
    }
    
    private static func shouldTryRequestReview() -> Bool {
        let appStartCountMinRequirement = 4
        let userEngagementCountMinRequirement = 10
        let userEngagementModulo = 10
        
        let appStartCount = PersistedCounter.getCount(withKey: appStartupCountKey)
        let userEngagementCount = PersistedCounter.getCount(withKey: userEngagementCountKey)
        
        return appStartCount >= appStartCountMinRequirement
            && userEngagementCount >= userEngagementCountMinRequirement
            && userEngagementCount % userEngagementModulo == 0
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
