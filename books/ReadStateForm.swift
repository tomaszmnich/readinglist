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

        // READ STATE
        let readStateSection = Section()
        readStateSection.append(SegmentedRow<BookReadState>(readStateKey) {
            $0.title = "Read State"
            $0.options = [.toRead, .reading, .finished]
            // Set a value here so we can be sure that the read state option is *never* null.
            $0.value = .toRead
        }.onChange{_ in
            self.OnChange()
        })
        form.append(readStateSection)
        
        // STARTED READING
        let startedReadingSection = Section() {
            $0.hidden = Condition.function([readStateKey]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowBy(tag: self.readStateKey)!
                return readStateRow.value == .toRead
            }
        }
        startedReadingSection.append(DateRow(dateStartedKey){
            $0.title = "Started Reading"
        }.onChange{_ in
            self.OnChange()
        }
        .cellUpdate{ _, _ in
            self.OnChange()
        })
        form.append(startedReadingSection)
        
        // FINISHED READING
        let finishedReadingSection = Section() {
            $0.hidden = Condition.function([self.readStateKey]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowBy(tag: self.readStateKey)!
                return readStateRow.value != .finished
            }
        }
        finishedReadingSection.append(DateRow(dateFinishedKey){
            $0.title = "Finished Reading"
        }.onChange{_ in
            self.OnChange()
        }
        .cellUpdate{ _, _ in
            self.OnChange()
        })
        form.append(finishedReadingSection)
    }
    
    func OnChange() {
        // Should be overriden
    }
    
    var ReadState: BookReadState {
        get { return form.values()[readStateKey] as! BookReadState }
        set { form.setValues([readStateKey: newValue]) }
    }
    
    var StartedReading: Date? {
        get { return form.values()[dateStartedKey] as? Date }
        set { form.setValues([dateStartedKey: newValue]) }
    }
    
    var FinishedReading: Date? {
        get { return form.values()[dateFinishedKey] as? Date }
        set { form.setValues([dateFinishedKey: newValue]) }
    }
    
    func IsValid() -> Bool {
        // Check that the relevant dates have been set.
        switch ReadState {
        case .toRead:
            return true
        case .reading:
            return StartedReading != nil
        case .finished:
            return StartedReading != nil && FinishedReading != nil && StartedReading!.compare(FinishedReading!) != .orderedDescending
        }
    }
}
