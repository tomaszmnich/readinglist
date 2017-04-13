//
//  BarcodeScanSimulationViewController.swift
//  books
//
//  Created by Andrew Bennet on 11/04/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka
import SVProgressHUD

class DebugSettingsViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let showFixedImageSection = Section(header: "Screenshot helpers", footer: "Whether to show a fixed, preloaded image of a barcode when the barcode scan view is loaded. This can be useful for generating screenshots.")
        showFixedImageSection.append(SwitchRow() {
            $0.title = "Show Fixed Image"
            $0.value = DebugSettings.useFixedBarcodeScanImage
            $0.onChange {
                DebugSettings.useFixedBarcodeScanImage = $0.value!
            }
        })
        form.append(showFixedImageSection)
        
        let importTestDataSection = Section(header: "Test data", footer: "Import a set of data for both testing and screenshots")
        importTestDataSection.append(ButtonRow() {
            $0.title = "Import Test Data"
            $0.onCellSelection { _,_ in
                self.loadTestData()
            }
        })
        form.append(importTestDataSection)
        
        let simulationOptions = SelectableSection<ListCheckRow<BarcodeScanSimulation>>("Barcode scan behaviour", selectionType: .singleSelection(enableDeselection: true))
        let currentValue = DebugSettings.barcodeScanSimulation
        for option: BarcodeScanSimulation in [.noCameraPermissions, .validIsbn, .unfoundIsbn, .existingIsbn] {
            simulationOptions.append(ListCheckRow<BarcodeScanSimulation>(){
                $0.title = option.titleText
                $0.selectableValue = option
                $0.value = (option == currentValue ? option : nil)
                $0.onChange{
                    DebugSettings.barcodeScanSimulation = $0.value
                }
            })
        }
        form.append(simulationOptions)
    }
    
    func loadTestData() {
        
        appDelegate.booksStore.deleteAll()
        let csvPath = Bundle.main.url(forResource: "examplebooks", withExtension: "csv")
        
        SVProgressHUD.show(withStatus: "Loading Data...")
        
        BookImport.importFrom(csvFile: csvPath!, supplementBooks: true) { importedCount, duplicateCount, invalidCount in
            var statusMessage = "\(importedCount) books imported."
            
            if duplicateCount != 0 {
                statusMessage += " \(duplicateCount) rows ignored due pre-existing data."
            }
            
            if invalidCount != 0 {
                statusMessage += " \(invalidCount) rows ignored due to invalid data."
            }
            SVProgressHUD.dismiss()
            SVProgressHUD.showInfo(withStatus: statusMessage)
        }
    }
}
