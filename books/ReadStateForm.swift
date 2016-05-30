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
            $0.options = [.ToRead, .Reading, .Finished]
            // Set a value here so we can be sure that the read state option is *never* null.
            $0.value = .ToRead
        }.onChange{_ in
            self.OnChange()
        })
        form.append(readStateSection)
        
        // STARTED READING
        let startedReadingSection = Section() {
            $0.hidden = Condition.Function([readStateKey]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowByTag(self.readStateKey)!
                return readStateRow.value == .ToRead
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
            $0.hidden = Condition.Function([self.readStateKey]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowByTag(self.readStateKey)!
                return readStateRow.value != .Finished
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
    
    var StartedReading: NSDate? {
        get { return form.values()[dateStartedKey] as? NSDate }
        set { form.setValues([dateStartedKey: newValue]) }
    }
    
    var FinishedReading: NSDate? {
        get { return form.values()[dateFinishedKey] as? NSDate }
        set { form.setValues([dateFinishedKey: newValue]) }
    }
    
    func IsValid() -> Bool {
        // Check that the relevant dates have been set.
        switch ReadState {
        case .ToRead:
            return true
        case .Reading:
            return StartedReading != nil
        case .Finished:
            return StartedReading != nil && FinishedReading != nil && StartedReading!.compare(FinishedReading!) != .OrderedDescending
        }
    }
}