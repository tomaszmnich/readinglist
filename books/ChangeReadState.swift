//
//  ChangeReadState.swift
//  books
//
//  Created by Andrew Bennet on 24/05/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Eureka
import UIKit

struct ReadStatePageInputs {
    var readState: BookReadState!
    var dateStarted: NSDate?
    var dateFinished: NSDate?
}

class ChangeReadState: FormViewController {

    let readStateKey = "book-read-state"
    let dateStartedKey = "date-started"
    let dateFinishedKey = "date-finished"
    
    var previousReadStateValue: BookReadState?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let readStateSection = Section()
        readStateSection.append(SegmentedRow<BookReadState>(readStateKey) {
            $0.title = "Read State"
            $0.options = [.ToRead, .Reading, .Finished]
        }.onChange{
            self.onReadStateChange($0)
        })
        form.append(readStateSection)
        
        let startedReadingSection = Section() {
            $0.hidden = Condition.Function([readStateKey]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowByTag(self.readStateKey)!
                return readStateRow.value == .ToRead
            }
        }
        startedReadingSection.append(DateRow(dateStartedKey){
            $0.title = "Started Reading"
        })
        form.append(startedReadingSection)
        
        let finishedReadingSection = Section() {
            $0.hidden = Condition.Function([self.readStateKey]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowByTag(self.readStateKey)!
                return readStateRow.value != .Finished
            }
        }
        finishedReadingSection.append(DateRow(dateFinishedKey){
            $0.title = "Finished Reading"
        })
        form.append(finishedReadingSection)
    }
    
    func onReadStateChange(row: SegmentedRow<BookReadState>) {
        // If we were on a different read state to now, and it is more "progressed", add a default value for the dates
        let formValues = self.getValues()
        if formValues.readState?.rawValue > previousReadStateValue?.rawValue {
            if formValues.readState == .ToRead {
                form.setValues([dateStartedKey: NSDate()])
            }
            else if formValues.readState == .Finished {
                form.setValues([dateFinishedKey: NSDate()])
            }
        }
        previousReadStateValue = formValues.readState
    }

    func setValues(inputs: ReadStatePageInputs) {
        previousReadStateValue = getValues().readState
        form.setValues([
            readStateKey: inputs.readState,
            dateStartedKey: inputs.dateStarted,
            dateFinishedKey: inputs.dateFinished])
    }
    
    func getValues() -> ReadStatePageInputs {
        let formValues = form.values()
        return ReadStatePageInputs(readState: formValues[readStateKey] as? BookReadState, dateStarted: formValues[dateStartedKey] as? NSDate, dateFinished: formValues[dateFinishedKey] as? NSDate)
    }
    
    func isValid() -> Bool {
        let formValues = getValues()
        
        guard let readState = formValues.readState else {
            return false
        }
        switch readState {
        case .ToRead:
            return true
        case .Reading:
            return formValues.dateStarted != nil
        case .Finished:
            return formValues.dateStarted != nil && formValues.dateFinished != nil // TODO: check date order?
        }
    }
}