//
//  AddBookOptionsViewController.swift
//  books
//
//  Created by Andrew Bennet on 30/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka

class AddBookOptions: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scanBarcodeSection = Section()
        scanBarcodeSection.append(ButtonRow(){
            $0.title = "Scan Barcode"
        }.onCellSelection{ _ in
            self.performSegueWithIdentifier("scanBarcodeSegue", sender: self)
        })
        form.append(scanBarcodeSection)
        
        let addManuallySection = Section()
        addManuallySection.append(ButtonRow(){
            $0.title = "Add Manually"
        }.onCellSelection{ _ in
            self.performSegueWithIdentifier("addBookManuallySegue", sender: self)
        })
        form.append(addManuallySection)
        
        // A button for loading test data, when in Debug mode
        #if DEBUG
            let addTestDataSection = Section()
            addTestDataSection.append(ButtonRow(){
                $0.title = "Add Test Data"
                }.onCellSelection{ _ in
                    TestData.loadTestData()
                    self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
                })
            form.append(addTestDataSection)
        #endif
    }
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
}