//
//  EditBookViewController.swift
//  books
//
//  Created by Andrew Bennet on 10/04/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation
import Eureka
import UIKit

class CreateBook: FormViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var initialBookMetadata: BookMetadata?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setStateOfDoneButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bookDetailsSection = Section("Book details")
        bookDetailsSection.append(SegmentedRow<BookReadState>("book-read-state") {
            $0.options = [.Reading, .ToRead, .Finished]
            $0.value = (self.navigationController as! NavWithReadState).readState
        })
        bookDetailsSection.append(TextRow("title") {
            $0.placeholder = "Title"
            $0.value = initialBookMetadata?.title
        }.onChange{ _ in
            self.setStateOfDoneButton()
        })
        bookDetailsSection.append(TextRow("author") {
            $0.placeholder = "Author"
            $0.value = initialBookMetadata?.authorList
        }.onChange{ _ in
            self.setStateOfDoneButton()
        })
        bookDetailsSection.append(TextAreaRow("description") {
            $0.placeholder = "Description"
            $0.value = initialBookMetadata?.bookDescription
        })
        form.append(bookDetailsSection)
        
        let startedReadingSection = Section("Started Reading") {
            $0.hidden = Condition.Function(["book-read-state"]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowByTag("book-read-state")!
                return readStateRow.value == .ToRead
            }
        }
        startedReadingSection.append(DateRow("date-started"){
            $0.value = initialBookMetadata?.startedReading ?? NSDate()
        })
        form.append(startedReadingSection)
        
        let finishedReadingSection = Section("Finished Reading") {
            $0.hidden = Condition.Function(["book-read-state"]) {
                let readStateRow: SegmentedRow<BookReadState> = $0.rowByTag("book-read-state")!
                return readStateRow.value != .Finished
            }
        }
        finishedReadingSection.append(DateRow("date-finished"){
            $0.value = initialBookMetadata?.finishedReading ?? NSDate()
        })
        form.append(finishedReadingSection)
        
        /*let bookCoverSection = Section("Book Cover")
        bookCoverSection.append(ImageRow("Cover Image"))
        form.append(bookCoverSection)*/
    }
    
    func setStateOfDoneButton() {
        let enteredValues = form.values()
        if (enteredValues["title"] as? String)?.isEmpty ?? true {
            doneButton.enabled = false
        }
        else if (enteredValues["author"] as? String)?.isEmpty ?? true {
            doneButton.enabled = false
        }
        else {
            doneButton.enabled = true
        }
    }
    
    @IBAction func doneWasPressed(sender: AnyObject) {
        let enteredValues = form.values()
        
        let bookMetadata = BookMetadata()
        bookMetadata.title = enteredValues["title"] as! String
        bookMetadata.authorList = enteredValues["author"] as? String
        bookMetadata.bookDescription = enteredValues["description"] as? String
        
        bookMetadata.readState = enteredValues["book-read-state"] as! BookReadState
        
        if bookMetadata.readState == .Reading {
            bookMetadata.startedReading = enteredValues["started-reading"] as? NSDate
        }
        if bookMetadata.readState == .Finished {
            bookMetadata.finishedReading = enteredValues["finished-reading"] as? NSDate
        }
        
        appDelegate.booksStore.CreateBook(bookMetadata)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}