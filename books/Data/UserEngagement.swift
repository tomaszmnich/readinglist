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
import Firebase

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
        case searchOnline = "Search_Online"
        case scanBarcode = "Scan_Barcode"
        case addManualBook = "Add_Manual_Book"
        case csvImport = "CSV_Import"
        case csvExport = "CSV_Export"
        case transitionReadState = "Transition_Read_State"
        case bulkEditReadState = "Bulk_Edit_Read_State"
        case deleteBook = "Delete_Book"
        case bulkDeleteBook = "Bulk_Delete_Book"
        case editBook = "Edit_Book"
        case editReadState = "Edit_Read_State"
        case searchOnlineQuickAction = "Quick_Action_Search_Online"
        case scanBarcodeQuickAction = "Quick_Action_Scan_Barcode"
        case spotlightSearch = "Spotlight_Search"
        case searchOnlineMultiple = "Search_Online_Multiple"
        case disableAnalytics = "Disable_Analytics"
        case enableAnalytics = "Enable_Analytics"
        case disableCrashReports = "Disable_Crash_Reports"
        case enableCrashReports = "Enable_Crash_Reports"
    }
    
    static func logEvent(_ event: Event) {
        Analytics.logEvent(event.rawValue, parameters: nil)
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
