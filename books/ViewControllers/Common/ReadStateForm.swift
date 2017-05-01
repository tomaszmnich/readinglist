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

    let readStateKey = "book-read-state"
    let dateStartedKey = "date-started"
    let dateFinishedKey = "date-finished"
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
                    return self.readState == .toRead
                }
            }
        
            <<< DateRow(dateStartedKey) {
                $0.title = "Started Reading"
                $0.maximumDate = Date.startOfToday()
                // Set a value here so we can be sure that the started date is *never* null.
                $0.value = Date.startOfToday()
                $0.onChange {[unowned self] _ in
                    self.validate()
                }
            }
        
            <<< DateRow(dateFinishedKey) {
                $0.title = "Finished Reading"
                $0.maximumDate = Date.startOfToday()
                $0.hidden = Condition.function([readStateKey]) {[unowned self] _ in
                    return self.readState != .finished
                }
                // Set a value here so we can be sure that the finished date is *never* null.
                $0.value = Date.startOfToday()
                $0.onChange{ [unowned self] _ in
                    self.validate()
                }
            }
    }
    
    private func validate() {
        if self.readState == .finished {
            formValidated(isValid:
                startedReading.compareIgnoringTime(finishedReading) != .orderedDescending)
        }
        else {
            formValidated(isValid: true)
        }
    }
    
    func formValidated(isValid: Bool) {
        // Should be overriden
    }
    
    var readState: BookReadState {
        get { return form.values()[readStateKey] as! BookReadState }
        set { form.setValues([readStateKey: newValue]) }
    }
    
    var startedReading: Date {
        get { return form.values(includeHidden: true)[dateStartedKey] as! Date }
        set { form.setValues([dateStartedKey: newValue]) }
    }
    
    var finishedReading: Date {
        get { return form.values(includeHidden: true)[dateFinishedKey] as! Date }
        set { form.setValues([dateFinishedKey: newValue]) }
    }
}
