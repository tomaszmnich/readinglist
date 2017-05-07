//
//  ChangeReadState.swift
//  books
//
//  Created by Andrew Bennet on 24/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Eureka
import UIKit

class ReadStateForm: FormViewController {

    private let readStateKey = "book-read-state"
    private let dateStartedKey = "date-started"
    private let dateFinishedKey = "date-finished"
    private let notesKey = "notes"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let now = Date()

        form +++ Section(header: "Current State", footer: "")
            <<< SegmentedRow<BookReadState>(readStateKey) {
                $0.options = [.toRead, .reading, .finished]
                // Set a value here so we can be sure that the read state option is *never* null.
                $0.value = .toRead
                $0.onChange {[unowned self] _ in
                    self.validate()
                }
            }
        
        +++ Section(header: "Reading Log", footer: "") {
            $0.hidden = Condition.function([readStateKey]) {[unowned self] _ in
                return self.readState.value! == .toRead
            }
        }
            <<< DateRow(dateStartedKey) {
                $0.title = "Started"
                $0.maximumDate = Date.startOfToday()
                // Set a value here so we can be sure that the started date is *never* null.
                $0.value = now
                $0.onChange {[unowned self] cell in
                    self.validate()
                }
            }
        
            <<< DateRow(dateFinishedKey) {
                $0.title = "Finished"
                $0.maximumDate = Date.startOfToday()
                $0.hidden = Condition.function([readStateKey]) {[unowned self] _ in
                    return self.readState.value! != .finished
                }
                // Set a value here so we can be sure that the finished date is *never* null.
                $0.value = now
                $0.onChange{ [unowned self] _ in
                    self.validate()
                }
            }
        
        +++ Section(header: "Notes", footer: "")
            <<< TextAreaRow(notesKey){
                $0.placeholder = "Add your personal notes here..."
                }
            .cellSetup{
                $0.0.height = {return 150}
            }
    }
    
    private func validate() {
        if self.readState.value == .finished {
            formValidated(isValid:
                startedReading.value!.compareIgnoringTime(finishedReading.value!) != .orderedDescending)
        }
        else {
            formValidated(isValid: true)
        }
    }
    
    func formValidated(isValid: Bool) {
        // Should be overriden
    }
    
    var readState: SegmentedRow<BookReadState> {
        get { return form.rowBy(tag: readStateKey) as! SegmentedRow<BookReadState> }
    }
    
    var startedReading: DateRow {
        get { return form.rowBy(tag: dateStartedKey) as! DateRow }
    }
    
    var finishedReading: DateRow {
        get { return form.rowBy(tag: dateFinishedKey) as! DateRow }
    }
    
    var notes: TextAreaRow {
        get { return form.rowBy(tag: notesKey) as! TextAreaRow }
    }
}
