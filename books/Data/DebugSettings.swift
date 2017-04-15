//
//  Preferences.swift
//  books
//
//  Created by Andrew Bennet on 12/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation

enum BarcodeScanSimulation: Int {
    case normal = 1
    case noCameraPermissions = 2
    case validIsbn = 3
    case unfoundIsbn = 4
    case existingIsbn = 5
    
    var titleText: String {
        switch self {
        case .normal:
            return "Normal"
        case .noCameraPermissions:
            return "No Camera Permissions"
        case .validIsbn:
            return "Valid ISBN"
        case .unfoundIsbn:
            return "Not-found ISBN"
        case .existingIsbn:
            return "Existing ISBN"
        }
    }
}

class DebugSettings {
    private static let useFixedBarcodeScanImageKey = "useFixedBarcodeScanImage"
    
    /**
     This string should be an ISBN which is included in the test debug import data.
    */
    static let existingIsbn = "9781551998756"
    
    static var useFixedBarcodeScanImage: Bool {
        get {
            #if DEBUG
                return (UserDefaults.standard.value(forKey: useFixedBarcodeScanImageKey) as? Bool) ?? false
            #else
                return false
            #endif
        }
        set {
            #if DEBUG
                UserDefaults.standard.setValue(newValue, forKey: useFixedBarcodeScanImageKey)
            #endif
        }
    }
    
    private static let barcodeScanSimulationKey = "barcodeScanSimulation"
    
    static var barcodeScanSimulation: BarcodeScanSimulation? {
        get {
            #if DEBUG
                guard let rawValue = UserDefaults.standard.value(forKey: barcodeScanSimulationKey) as? Int else { return nil }
                return BarcodeScanSimulation.init(rawValue: rawValue)!
            #else
                return nil
            #endif
        }
        set {
            #if DEBUG
                UserDefaults.standard.setValue(newValue?.rawValue, forKey: barcodeScanSimulationKey)
            #endif
        }
    }
}
