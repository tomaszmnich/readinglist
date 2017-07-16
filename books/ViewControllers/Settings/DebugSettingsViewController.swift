//
//  DebugSettingsViewController.swift
//  books
//
//  Created by Andrew Bennet on 11/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

#if DEBUG
    
import Foundation
import Eureka
import SVProgressHUD
import SimulatorStatusMagic

class DebugSettingsViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section(header: "Screenshot helpers", footer: "Useful toggles for generating screenshots.")
            <<< SwitchRow() {
                $0.title = "Show Fixed Image"
                $0.value = DebugSettings.useFixedBarcodeScanImage
                $0.onChange {
                    DebugSettings.useFixedBarcodeScanImage = $0.value!
                }
            }
            <<< SwitchRow() {
                $0.title = "Pretty Status Bar"
                $0.value = SDStatusBarManager.sharedInstance().usingOverrides
                $0.onChange {
                    if $0.value! {
                        SDStatusBarManager.sharedInstance().enableOverrides()
                    }
                    else {
                        SDStatusBarManager.sharedInstance().disableOverrides()
                    }
                }
            }
        
        form +++ Section(header: "Test data", footer: "Import a set of data for both testing and screenshots")
            <<< ButtonRow() {
                $0.title = "Import Test Data"
                $0.onCellSelection { [unowned self] _,_ in
                    self.loadTestData()
                }
            }
        
        let simulationOptions = SelectableSection<ListCheckRow<BarcodeScanSimulation>>("Barcode scan behaviour", selectionType: .singleSelection(enableDeselection: true))
        let currentValue = DebugSettings.barcodeScanSimulation
        for option: BarcodeScanSimulation in [.normal, .noCameraPermissions, .validIsbn, .unfoundIsbn, .existingIsbn] {
            simulationOptions.append(ListCheckRow<BarcodeScanSimulation>(){
                $0.title = option.titleText
                $0.selectableValue = option
                $0.value = (option == currentValue ? option : nil)
                $0.onChange{
                    DebugSettings.barcodeScanSimulation = $0.value
                }
            })
        }
        form +++ simulationOptions
        
        form +++ Section("Debug Controls")
            <<< SwitchRow() {
                $0.title = "Show sort number"
                $0.value = DebugSettings.showSortNumber
                $0.onChange {
                    DebugSettings.showSortNumber = $0.value ?? false
                }
            }
            <<< SwitchRow() {
                $0.title = "Show cell reload control"
                $0.value = DebugSettings.showCellReloadControl
                $0.onChange {
                    DebugSettings.showCellReloadControl = $0.value ?? false
                }
        }
    }
    
    func loadTestData() {
        
        appDelegate.booksStore.deleteAll()
        let csvPath = Bundle.main.url(forResource: "examplebooks", withExtension: "csv")
        
        SVProgressHUD.show(withStatus: "Loading Data...")
        
        BookImporter(csvFileUrl: csvPath!, supplementBookCover: true, supplementBookMetadata: false, missingHeadersCallback: {
            print("Missing headers!")
        }) { importedCount, duplicateCount, invalidCount in

            var statusMessage = "\(importedCount) books imported."
            
            if duplicateCount != 0 {
                statusMessage += " \(duplicateCount) rows ignored due pre-existing data."
            }
            
            if invalidCount != 0 {
                statusMessage += " \(invalidCount) rows ignored due to invalid data."
            }
            SVProgressHUD.dismiss()
            SVProgressHUD.showInfo(withStatus: statusMessage)
        }.StartImport()
    }
}

#endif
